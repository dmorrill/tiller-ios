<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\GoogleSheetsService;
use App\Services\SheetAdapterService;
use App\Models\Sheet;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class TransactionController extends Controller
{
    protected GoogleSheetsService $sheetsService;
    protected SheetAdapterService $adapterService;

    public function __construct(
        GoogleSheetsService $sheetsService,
        SheetAdapterService $adapterService
    ) {
        $this->sheetsService = $sheetsService;
        $this->adapterService = $adapterService;
    }

    /**
     * Get all transactions with optional filters
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $user = $request->user();
            $sheet = $user->sheets()->where('sheet_type', 'transactions')->first();

            if (!$sheet) {
                return response()->json(['error' => 'No transaction sheet configured'], 404);
            }

            // Set up Google Sheets service with user's token
            $this->sheetsService->setAccessToken([
                'access_token' => $user->google_token,
                'refresh_token' => $user->google_refresh_token,
            ]);

            // Get transactions from sheet
            $range = "{$sheet->sheet_name}!A:Z"; // Get all columns
            $values = $this->sheetsService->getValues($sheet->spreadsheet_id, $range);

            if (empty($values)) {
                return response()->json(['transactions' => []]);
            }

            // Parse transactions
            $transactions = $this->parseTransactions($values, $sheet);

            // Apply filters
            if ($request->has('uncategorized')) {
                $transactions = collect($transactions)->filter(function ($t) {
                    return empty($t['category']);
                })->values();
            }

            if ($request->has('account')) {
                $account = $request->input('account');
                $transactions = collect($transactions)->filter(function ($t) use ($account) {
                    return $t['account'] === $account;
                })->values();
            }

            if ($request->has('from_date')) {
                $fromDate = $request->input('from_date');
                $transactions = collect($transactions)->filter(function ($t) use ($fromDate) {
                    return $t['date'] >= $fromDate;
                })->values();
            }

            // Pagination
            $perPage = $request->input('per_page', 50);
            $page = $request->input('page', 1);
            $total = count($transactions);
            $transactions = collect($transactions)
                ->slice(($page - 1) * $perPage, $perPage)
                ->values();

            return response()->json([
                'transactions' => $transactions,
                'meta' => [
                    'total' => $total,
                    'per_page' => $perPage,
                    'current_page' => $page,
                    'last_page' => ceil($total / $perPage),
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Error fetching transactions: ' . $e->getMessage());
            return response()->json([
                'error' => 'Failed to fetch transactions',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get a single transaction
     */
    public function show(Request $request, string $id): JsonResponse
    {
        try {
            $user = $request->user();
            $sheet = $user->sheets()->where('sheet_type', 'transactions')->first();

            if (!$sheet) {
                return response()->json(['error' => 'No transaction sheet configured'], 404);
            }

            // This would use the row identity service to find the specific transaction
            // For now, returning a placeholder
            return response()->json([
                'transaction' => [
                    'id' => $id,
                    // Transaction data would be fetched here
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Error fetching transaction: ' . $e->getMessage());
            return response()->json([
                'error' => 'Failed to fetch transaction',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update a transaction (category, note, tags)
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $request->validate([
            'category' => 'nullable|string|max:255',
            'note' => 'nullable|string|max:500',
            'tags' => 'nullable|array',
            'tags.*' => 'string|max:50',
        ]);

        try {
            $user = $request->user();
            $sheet = $user->sheets()->where('sheet_type', 'transactions')->first();

            if (!$sheet) {
                return response()->json(['error' => 'No transaction sheet configured'], 404);
            }

            // Set up Google Sheets service
            $this->sheetsService->setAccessToken([
                'access_token' => $user->google_token,
                'refresh_token' => $user->google_refresh_token,
            ]);

            // Get schema to find column positions
            $schema = json_decode($sheet->schema->columns, true);

            // Build updates array
            $updates = [];

            if ($request->has('category')) {
                $updates['category'] = $request->input('category');
            }

            if ($request->has('note')) {
                $updates['note'] = $request->input('note');
            }

            if ($request->has('tags')) {
                $updates['tags'] = implode(', ', $request->input('tags'));
            }

            // Use adapter service to safely update the transaction
            $this->adapterService->updateTransaction(
                $sheet,
                $id,
                $updates
            );

            // Log the update
            Log::info('Transaction updated', [
                'user_id' => $user->id,
                'transaction_id' => $id,
                'updates' => $updates,
            ]);

            return response()->json([
                'message' => 'Transaction updated successfully',
                'transaction' => [
                    'id' => $id,
                    ...$updates,
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Error updating transaction: ' . $e->getMessage());
            return response()->json([
                'error' => 'Failed to update transaction',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Create a new manual transaction
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'date' => 'required|date',
            'description' => 'required|string|max:255',
            'amount' => 'required|numeric',
            'account' => 'required|string|max:255',
            'category' => 'nullable|string|max:255',
            'note' => 'nullable|string|max:500',
            'tags' => 'nullable|array',
            'tags.*' => 'string|max:50',
        ]);

        try {
            $user = $request->user();
            $sheet = $user->sheets()->where('sheet_type', 'transactions')->first();

            if (!$sheet) {
                return response()->json(['error' => 'No transaction sheet configured'], 404);
            }

            // Set up Google Sheets service
            $this->sheetsService->setAccessToken([
                'access_token' => $user->google_token,
                'refresh_token' => $user->google_refresh_token,
            ]);

            // Prepare transaction data
            $schema = json_decode($sheet->schema->columns, true);
            $rowData = $this->buildRowData($request->all(), $schema);

            // Append to sheet
            $range = "{$sheet->sheet_name}!A:Z";
            $this->sheetsService->appendValues(
                $sheet->spreadsheet_id,
                $range,
                [$rowData]
            );

            return response()->json([
                'message' => 'Transaction created successfully',
                'transaction' => $request->all(),
            ], 201);

        } catch (\Exception $e) {
            Log::error('Error creating transaction: ' . $e->getMessage());
            return response()->json([
                'error' => 'Failed to create transaction',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Parse raw sheet values into transaction objects
     */
    protected function parseTransactions(array $values, Sheet $sheet): array
    {
        if (count($values) < 2) {
            return []; // No data rows
        }

        $headers = array_map('strtolower', $values[0]);
        $transactions = [];

        // Get column mappings
        $columnMap = [
            'date' => array_search('date', $headers),
            'description' => array_search('description', $headers),
            'amount' => array_search('amount', $headers),
            'account' => array_search('account', $headers),
            'category' => array_search('category', $headers),
            'note' => array_search('note', $headers),
            'tags' => array_search('tags', $headers),
            'id' => array_search('__mobile_app_id', $headers),
        ];

        // Parse data rows
        for ($i = 1; $i < count($values); $i++) {
            $row = $values[$i];

            $transaction = [
                'row' => $i + 1, // Row number in sheet (1-indexed)
                'id' => $columnMap['id'] !== false ? ($row[$columnMap['id']] ?? null) : "row_$i",
                'date' => $columnMap['date'] !== false ? ($row[$columnMap['date']] ?? null) : null,
                'description' => $columnMap['description'] !== false ? ($row[$columnMap['description']] ?? null) : null,
                'amount' => $columnMap['amount'] !== false ? floatval($row[$columnMap['amount']] ?? 0) : 0,
                'account' => $columnMap['account'] !== false ? ($row[$columnMap['account']] ?? null) : null,
                'category' => $columnMap['category'] !== false ? ($row[$columnMap['category']] ?? null) : null,
                'note' => $columnMap['note'] !== false ? ($row[$columnMap['note']] ?? null) : null,
                'tags' => $columnMap['tags'] !== false ? ($row[$columnMap['tags']] ?? null) : null,
            ];

            // Skip empty rows
            if (empty($transaction['description']) && empty($transaction['amount'])) {
                continue;
            }

            $transactions[] = $transaction;
        }

        return $transactions;
    }

    /**
     * Build row data array for appending to sheet
     */
    protected function buildRowData(array $data, array $schema): array
    {
        $row = [];

        foreach ($schema as $column => $info) {
            $key = strtolower($column);

            if (isset($data[$key])) {
                $row[$info['position']] = $data[$key];
            } else {
                $row[$info['position']] = '';
            }
        }

        // Ensure array is properly indexed
        ksort($row);

        return array_values($row);
    }
}