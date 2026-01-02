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
    static let baseURL = "https://your-production-url.com/api"
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
            return "Unauthorized - please sign in again"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown error")"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

// MARK: - API Response
struct APIResponse<T: Decodable>: Decodable {
    let data: T?
    let message: String?
    let errors: [String: [String]]?
}

// MARK: - API Client
class APIClient: ObservableObject {
    static let shared = APIClient()

    private let session: URLSession
    @Published private(set) var authToken: String?

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = APIConfig.timeout
        configuration.httpAdditionalHeaders = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        self.session = URLSession(configuration: configuration)

        // Load saved auth token
        self.authToken = UserDefaults.standard.string(forKey: "authToken")
    }

    // MARK: - Token Management
    func setAuthToken(_ token: String?) {
        self.authToken = token
        if let token = token {
            UserDefaults.standard.set(token, forKey: "authToken")
        } else {
            UserDefaults.standard.removeObject(forKey: "authToken")
        }
    }

    // MARK: - Request Builder
    private func buildRequest(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil
    ) throws -> URLRequest {
        guard let url = URL(string: "\(APIConfig.baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        // Add auth token if available
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Add body if provided
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        return request
    }

    // MARK: - Request Execution
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        responseType: T.Type
    ) async throws -> T {
        let request = try buildRequest(endpoint: endpoint, method: method, body: body)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown
            }

            // Handle different status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success
                do {
                    let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                    return decodedResponse
                } catch {
                    throw APIError.decodingError(error)
                }

            case 401:
                // Unauthorized - clear token
                setAuthToken(nil)
                throw APIError.unauthorized

            case 400...499:
                // Client error
                let errorMessage = String(data: data, encoding: .utf8)
                throw APIError.serverError(httpResponse.statusCode, errorMessage)

            case 500...599:
                // Server error
                let errorMessage = String(data: data, encoding: .utf8)
                throw APIError.serverError(httpResponse.statusCode, errorMessage)

            default:
                throw APIError.unknown
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
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

// MARK: - Convenience Extensions
extension APIClient {
    // Health Check
    func healthCheck() async throws -> HealthResponse {
        return try await request(
            endpoint: "/health",
            responseType: HealthResponse.self
        )
    }

    // Authentication
    func signInWithGoogle(authCode: String) async throws -> AuthResponse {
        let body = GoogleAuthRequest(auth_code: authCode)
        return try await request(
            endpoint: "/auth/mobile",
            method: .post,
            body: body,
            responseType: AuthResponse.self
        )
    }

    func refreshToken() async throws -> AuthResponse {
        return try await request(
            endpoint: "/auth/refresh",
            method: .post,
            responseType: AuthResponse.self
        )
    }

    func signOut() async throws {
        _ = try await request(
            endpoint: "/auth/logout",
            method: .post,
            responseType: EmptyResponse.self
        )
        setAuthToken(nil)
    }

    // Sheets
    func getSheets() async throws -> [Sheet] {
        return try await request(
            endpoint: "/sheets",
            responseType: SheetsResponse.self
        ).data
    }

    func connectSheet(spreadsheetId: String) async throws -> Sheet {
        let body = ConnectSheetRequest(spreadsheet_id: spreadsheetId)
        return try await request(
            endpoint: "/sheets",
            method: .post,
            body: body,
            responseType: SheetResponse.self
        ).data
    }

    func disconnectSheet(id: String) async throws {
        _ = try await request(
            endpoint: "/sheets/\(id)",
            method: .delete,
            responseType: EmptyResponse.self
        )
    }

    // Transactions
    func getTransactions(sheetId: String? = nil) async throws -> [Transaction] {
        var endpoint = "/transactions"
        if let sheetId = sheetId {
            endpoint += "?sheet_id=\(sheetId)"
        }
        return try await request(
            endpoint: endpoint,
            responseType: TransactionsResponse.self
        ).data
    }

    func updateTransaction(id: String, updates: TransactionUpdate) async throws -> Transaction {
        return try await request(
            endpoint: "/transactions/\(id)",
            method: .patch,
            body: updates,
            responseType: TransactionResponse.self
        ).data
    }

    // Categories
    func getCategories() async throws -> [Category] {
        return try await request(
            endpoint: "/categories",
            responseType: CategoriesResponse.self
        ).data
    }

    func createCategory(name: String, group: String? = nil) async throws -> Category {
        let body = CreateCategoryRequest(name: name, group: group)
        return try await request(
            endpoint: "/categories",
            method: .post,
            body: body,
            responseType: CategoryResponse.self
        ).data
    }
}

// MARK: - Request/Response Models
struct GoogleAuthRequest: Encodable {
    let auth_code: String
}

struct ConnectSheetRequest: Encodable {
    let spreadsheet_id: String
}

struct CreateCategoryRequest: Encodable {
    let name: String
    let group: String?
}

struct TransactionUpdate: Encodable {
    let category: String?
    let note: String?
    let tags: String?
}

// Response wrappers
struct HealthResponse: Decodable {
    let status: String
    let version: String
    let timestamp: String
}

struct AuthResponse: Decodable {
    let token: String
    let user: User
}

struct EmptyResponse: Decodable {}

struct SheetsResponse: Decodable {
    let data: [Sheet]
}

struct SheetResponse: Decodable {
    let data: Sheet
}

struct TransactionsResponse: Decodable {
    let data: [Transaction]
}

struct TransactionResponse: Decodable {
    let data: Transaction
}

struct CategoriesResponse: Decodable {
    let data: [Category]
}

struct CategoryResponse: Decodable {
    let data: Category
}