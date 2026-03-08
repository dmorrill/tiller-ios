<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\GoogleSheetsService;
use App\Models\Sheet;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;

class TransactionController extends Controller
{
    /**
     * Safe-to-write columns. Never write to formula or system columns.
     */
    protected const WRITABLE_COLUMNS = ['Category', 'Note'];

    public function __construct(
        protected GoogleSheetsService $sheetsService,
    ) {}

    /**
     * Get all transactions with optional filters.
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $sheet = $request->user()->sheets()->first();

            if (!$sheet || !$sheet->schema) {
                return response()->json(['error' => 'No sheet connected. Connect a Tiller sheet first.'], 404);
            }

            $mappings = $sheet->schema->column_mappings['transactions'] ?? null;
            if (!$mappings) {
                return response()->json(['error' => 'Sheet schema not detected. Re-connect your sheet.'], 422);
            }

            $this->sheetsService->authenticateServiceAccount();
            $rows = $this->sheetsService->getValues($sheet->spreadsheet_id, 'Transactions!A:Z');

            if (empty($rows) || count($rows) < 2) {
                return response()->json(['transactions' => [], 'meta' => ['total' => 0]]);
            }

            $transactions = $this->parseTransactions(array_slice($rows, 1), $mappings);

            // Filters
            if ($request->has('uncategorized')) {
                $transactions = collect($transactions)->filter(fn ($t) => empty($t['category']))->values()->all();
            }
            if ($request->has('account')) {
                $account = $request->input('account');
                $transactions = collect($transactions)->filter(fn ($t) => $t['account'] === $account)->values()->all();
            }
            if ($request->has('from_date')) {
                $from = $request->input('from_date');
                $transactions = collect($transactions)->filter(fn ($t) => ($t['date'] ?? '') >= $from)->values()->all();
            }

            // Pagination
            $perPage = (int) $request->input('per_page', 50);
            $page = (int) $request->input('page', 1);
            $total = count($transactions);
            $paged = array_slice($transactions, ($page - 1) * $perPage, $perPage);

            return response()->json([
                'transactions' => array_values($paged),
                'meta' => [
                    'total' => $total,
                    'per_page' => $perPage,
                    'current_page' => $page,
                    'last_page' => (int) ceil($total / $perPage),
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('Error fetching transactions: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to fetch transactions'], 500);
        }
    }

    /**
     * Get a single transaction by Transaction ID.
     */
    public function show(Request $request, string $id): JsonResponse
    {
        try {
            $sheet = $request->user()->sheets()->first();
            if (!$sheet || !$sheet->schema) {
                return response()->json(['error' => 'No sheet connected'], 404);
            }

            $mappings = $sheet->schema->column_mappings['transactions'] ?? [];
            $this->sheetsService->authenticateServiceAccount();
            $rows = $this->sheetsService->getValues($sheet->spreadsheet_id, 'Transactions!A:Z');

            if (empty($rows) || count($rows) < 2) {
                return response()->json(['error' => 'Transaction not found'], 404);
            }

            $txIdCol = $mappings['Transaction ID'] ?? null;
            foreach (array_slice($rows, 1) as $index => $row) {
                $rowTxId = trim($row[$txIdCol] ?? '');
                if ($rowTxId === $id) {
                    return response()->json([
                        'transaction' => $this->rowToTransaction($row, $mappings, $index + 2),
                    ]);
                }
            }

            return response()->json(['error' => 'Transaction not found'], 404);
        } catch (\Exception $e) {
            Log::error('Error fetching transaction: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to fetch transaction'], 500);
        }
    }

    /**
     * Update a transaction's Category or Note. Safe writes only.
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $request->validate([
            'category' => 'nullable|string|max:255',
            'note' => 'nullable|string|max:500',
        ]);

        try {
            $sheet = $request->user()->sheets()->first();
            if (!$sheet || !$sheet->schema) {
                return response()->json(['error' => 'No sheet connected'], 404);
            }

            $mappings = $sheet->schema->column_mappings['transactions'] ?? [];
            $this->sheetsService->authenticateServiceAccount();

            // Find the row by Transaction ID
            $rows = $this->sheetsService->getValues($sheet->spreadsheet_id, 'Transactions!A:Z');
            $txIdCol = $mappings['Transaction ID'] ?? null;

            if ($txIdCol === null) {
                return response()->json(['error' => 'Schema missing Transaction ID column'], 422);
            }

            $targetRow = null;
            foreach (array_slice($rows, 1) as $index => $row) {
                if (trim($row[$txIdCol] ?? '') === $id) {
                    $targetRow = $index + 2; // 1-indexed, skip header
                    break;
                }
            }

            if (!$targetRow) {
                return response()->json(['error' => 'Transaction not found'], 404);
            }

            // Write only safe columns
            $updates = [];
            foreach (self::WRITABLE_COLUMNS as $col) {
                $inputKey = strtolower($col);
                if ($request->has($inputKey) && isset($mappings[$col])) {
                    $colIndex = $mappings[$col];
                    $colLetter = $this->columnLetter($colIndex);
                    $range = "Transactions!{$colLetter}{$targetRow}";
                    $value = $request->input($inputKey) ?? '';

                    $this->sheetsService->updateValues(
                        $sheet->spreadsheet_id,
                        $range,
                        [[$value]],
                    );

                    $updates[$inputKey] = $value;
                }
            }

            Log::info('Transaction updated', [
                'user_id' => $request->user()->id,
                'transaction_id' => $id,
                'row' => $targetRow,
                'updates' => $updates,
            ]);

            return response()->json([
                'message' => 'Transaction updated successfully',
                'updates' => $updates,
            ]);
        } catch (\Exception $e) {
            Log::error('Error updating transaction: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to update transaction'], 500);
        }
    }

    /**
     * Create a new manual transaction (append to sheet).
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
        ]);

        try {
            $sheet = $request->user()->sheets()->first();
            if (!$sheet || !$sheet->schema) {
                return response()->json(['error' => 'No sheet connected'], 404);
            }

            $mappings = $sheet->schema->column_mappings['transactions'] ?? [];
            $this->sheetsService->authenticateServiceAccount();

            // Build row based on schema mappings
            $maxCol = max(array_values($mappings)) + 1;
            $row = array_fill(0, $maxCol, '');

            $fieldMap = [
                'Date' => $request->input('date'),
                'Description' => $request->input('description'),
                'Amount' => $request->input('amount'),
                'Account' => $request->input('account'),
                'Category' => $request->input('category', ''),
            ];

            foreach ($fieldMap as $col => $value) {
                if (isset($mappings[$col])) {
                    $row[$mappings[$col]] = $value;
                }
            }

            $this->sheetsService->appendValues(
                $sheet->spreadsheet_id,
                'Transactions!A:Z',
                [$row],
            );

            return response()->json([
                'message' => 'Transaction created successfully',
                'transaction' => $request->only(['date', 'description', 'amount', 'account', 'category']),
            ], 201);
        } catch (\Exception $e) {
            Log::error('Error creating transaction: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to create transaction'], 500);
        }
    }

    /**
     * Parse data rows using schema column mappings.
     */
    protected function parseTransactions(array $dataRows, array $mappings): array
    {
        $transactions = [];

        foreach ($dataRows as $index => $row) {
            $tx = $this->rowToTransaction($row, $mappings, $index + 2);

            // Skip empty rows
            if (empty($tx['description']) && empty($tx['amount'])) {
                continue;
            }

            $transactions[] = $tx;
        }

        return $transactions;
    }

    protected function rowToTransaction(array $row, array $mappings, int $sheetRow): array
    {
        $get = fn (string $col) => trim($row[$mappings[$col] ?? -1] ?? '');

        return [
            'row' => $sheetRow,
            'transaction_id' => $get('Transaction ID'),
            'date' => $get('Date'),
            'description' => $get('Description'),
            'category' => $get('Category'),
            'amount' => (float) ($get('Amount') ?: 0),
            'account' => $get('Account'),
            'account_number' => $get('Account #'),
            'institution' => $get('Institution'),
            'month' => $get('Month'),
            'week' => $get('Week'),
            'check_number' => $get('Check Number'),
            'full_description' => $get('Full Description'),
            'date_added' => $get('Date Added'),
            'categorized_date' => $get('Categorized Date'),
        ];
    }

    /**
     * Convert 0-based column index to letter (0=A, 1=B, ..., 25=Z, 26=AA).
     */
    protected function columnLetter(int $index): string
    {
        $letter = '';
        $index++;
        while ($index > 0) {
            $index--;
            $letter = chr(65 + ($index % 26)) . $letter;
            $index = intdiv($index, 26);
        }
        return $letter;
    }
}
