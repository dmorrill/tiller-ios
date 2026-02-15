//
//  APIClient.swift
//  TillerCompanion
//
//  API client for communicating with Laravel backend
//

import Foundation

// MARK: - API Configuration
struct APIConfig {
    #if DEBUG
    static let baseURL = "http://localhost:8000/api"
    #else
    static let baseURL = "http://161.35.255.184/api"
    #endif

    static let timeout: TimeInterval = 30.0
}

// MARK: - API Errors
enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case networkError(Error)
    case unauthorized
    case serverError(Int, String?)
    case validationError(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized — please sign in again"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown")"
        case .validationError(let message):
            return message
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

// MARK: - HTTP Methods
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - API Client
class APIClient: ObservableObject {
    static let shared = APIClient()

    private let session: URLSession
    @Published private(set) var authToken: String?

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfig.timeout
        config.httpAdditionalHeaders = [
            "Accept": "application/json",
            "Content-Type": "application/json",
        ]
        self.session = URLSession(configuration: config)

        // Token is now loaded from Keychain by AuthService
    }

    // MARK: - Token Management
    func setAuthToken(_ token: String?) {
        self.authToken = token
    }

    // MARK: - Generic Request
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: "\(APIConfig.baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(T.self, from: data)
        case 401:
            setAuthToken(nil)
            throw APIError.unauthorized
        case 422:
            // Validation error — try to parse message
            if let json = try? JSONDecoder().decode(ValidationErrorResponse.self, from: data) {
                let messages = json.errors?.values.flatMap { $0 }.joined(separator: "\n")
                    ?? json.message ?? "Validation failed"
                throw APIError.validationError(messages)
            }
            throw APIError.serverError(422, String(data: data, encoding: .utf8))
        default:
            let msg = String(data: data, encoding: .utf8)
            throw APIError.serverError(httpResponse.statusCode, msg)
        }
    }
}

// MARK: - Auth Endpoints
extension APIClient {
    func register(name: String, email: String, password: String) async throws -> AuthResponse {
        let body = RegisterBody(name: name, email: email, password: password, password_confirmation: password)
        return try await request(endpoint: "/auth/register", method: .post, body: body, responseType: AuthResponse.self)
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let body = LoginBody(email: email, password: password)
        return try await request(endpoint: "/auth/login", method: .post, body: body, responseType: AuthResponse.self)
    }

    func fetchUser() async throws -> UserInfoResponse {
        return try await request(endpoint: "/auth/user", responseType: UserInfoResponse.self)
    }

    func signOut() async throws {
        _ = try await request(endpoint: "/auth/logout", method: .post, responseType: EmptyResponse.self)
        setAuthToken(nil)
    }
}

// MARK: - Sheet Endpoints
extension APIClient {
    func getServiceAccountEmail() async throws -> ServiceAccountResponse {
        return try await request(endpoint: "/sheets/service-account", responseType: ServiceAccountResponse.self)
    }

    func connectSheet(url: String) async throws -> ConnectSheetResponse {
        let body = ConnectSheetBody(spreadsheet_url: url)
        return try await request(endpoint: "/sheets/connect", method: .post, body: body, responseType: ConnectSheetResponse.self)
    }

    func getSheets() async throws -> [SheetData] {
        let resp = try await request(endpoint: "/sheets", responseType: SheetsListResponse.self)
        return resp.data
    }
}

// MARK: - Transaction Endpoints
extension APIClient {
    func getTransactions(sheetId: String? = nil) async throws -> [Transaction] {
        var endpoint = "/transactions"
        if let sheetId = sheetId {
            endpoint += "?sheet_id=\(sheetId)"
        }
        return try await request(endpoint: endpoint, responseType: TransactionsResponse.self).data
    }

    func updateTransaction(id: String, updates: TransactionUpdate) async throws -> Transaction {
        return try await request(endpoint: "/transactions/\(id)", method: .patch, body: updates, responseType: TransactionResponse.self).data
    }
}

// MARK: - Request/Response Types

struct RegisterBody: Encodable {
    let name: String
    let email: String
    let password: String
    let password_confirmation: String
}

struct LoginBody: Encodable {
    let email: String
    let password: String
}

struct ConnectSheetBody: Encodable {
    let spreadsheet_url: String
}

struct TransactionUpdate: Encodable {
    let category: String?
    let note: String?
    let tags: String?
}

struct AuthResponse: Decodable {
    let user: User
    let accessToken: String
    let tokenType: String

    private enum CodingKeys: String, CodingKey {
        case user
        case accessToken = "access_token"
        case tokenType = "token_type"
    }
}

struct UserInfoResponse: Decodable {
    let id: Int
    let name: String
    let email: String
    let hasSheet: Bool
    let serviceAccountEmail: String?

    var user: User {
        User(id: "\(id)", email: email, name: name, googleId: nil, avatar: nil, settings: nil)
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, email
        case hasSheet = "has_sheet"
        case serviceAccountEmail = "service_account_email"
    }
}

struct ServiceAccountResponse: Decodable {
    let email: String
}

struct ConnectSheetResponse: Decodable {
    let message: String
    let data: SheetData
}

struct SheetData: Decodable, Identifiable {
    let id: Int
    let spreadsheetId: String
    let sheetName: String

    var stringId: String { "\(id)" }

    private enum CodingKeys: String, CodingKey {
        case id
        case spreadsheetId = "spreadsheet_id"
        case sheetName = "sheet_name"
    }
}

struct SheetsListResponse: Decodable {
    let data: [SheetData]
}

struct TransactionsResponse: Decodable {
    let data: [Transaction]
}

struct TransactionResponse: Decodable {
    let data: Transaction
}

struct ValidationErrorResponse: Decodable {
    let message: String?
    let errors: [String: [String]]?
}

struct EmptyResponse: Decodable {}

struct HealthResponse: Decodable {
    let status: String
    let version: String
    let timestamp: String
}
