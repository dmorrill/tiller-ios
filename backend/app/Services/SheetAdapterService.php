<?php

namespace App\Services;

use App\Models\Sheet;
use Illuminate\Support\Facades\Log;

class SheetAdapterService
{
    protected GoogleSheetsService $sheetsService;

    // Safe columns that can be written to
    const SAFE_COLUMNS = [
        'Category',
        'Note',
        'Tags',
        '__mobile_app_id'
    ];

    public function __construct(GoogleSheetsService $sheetsService)
    {
        $this->sheetsService = $sheetsService;
    }

    /**
     * Update a transaction in the sheet
     */
    public function updateTransaction(Sheet $sheet, string $transactionId, array $updates): void
    {
        // Get schema
        $schema = json_decode($sheet->schema->columns, true);

        // Find the row by mobile ID or composite key
        $rowNumber = $this->findRowByIdentifier($sheet, $transactionId);

        if (!$rowNumber) {
            throw new \Exception("Transaction not found: {$transactionId}");
        }

        // Build update ranges
        $updateRanges = [];

        foreach ($updates as $field => $value) {
            $columnInfo = $this->getColumnInfo($schema, $field);

            if (!$columnInfo) {
                Log::warning("Column not found for field: {$field}");
                continue;
            }

            // Validate column is safe to write
            if (!$this->isColumnSafe($columnInfo['header'])) {
                throw new \Exception("Cannot write to column: {$columnInfo['header']}");
            }

            // Check for formulas
            if ($this->hasFormula($sheet, $rowNumber, $columnInfo['letter'])) {
                throw new \Exception("Cannot overwrite formula in column: {$columnInfo['letter']}");
            }

            $range = "{$sheet->sheet_name}!{$columnInfo['letter']}{$rowNumber}";
            $updateRanges[] = [
                'range' => $range,
                'value' => $value,
            ];
        }

        // Perform updates
        foreach ($updateRanges as $update) {
            $this->sheetsService->updateValues(
                $sheet->spreadsheet_id,
                $update['range'],
                [[$update['value']]]
            );
        }

        Log::info('Transaction updated successfully', [
            'sheet_id' => $sheet->id,
            'transaction_id' => $transactionId,
            'row' => $rowNumber,
            'updates' => array_keys($updates),
        ]);
    }

    /**
     * Find row by mobile ID or composite key
     */
    protected function findRowByIdentifier(Sheet $sheet, string $identifier): ?int
    {
        // First try by mobile ID if available
        if ($sheet->schema->has_mobile_id_column) {
            $schema = json_decode($sheet->schema->columns, true);
            $idColumn = $this->getColumnInfo($schema, '__mobile_app_id');

            if ($idColumn) {
                $range = "{$sheet->sheet_name}!{$idColumn['letter']}:{$idColumn['letter']}";
                $values = $this->sheetsService->getValues($sheet->spreadsheet_id, $range);

                foreach ($values as $index => $row) {
                    if (isset($row[0]) && $row[0] === $identifier) {
                        return $index + 1; // Sheets are 1-indexed
                    }
                }
            }
        }

        // Fallback to row number if identifier looks like "row_X"
        if (preg_match('/^row_(\d+)$/', $identifier, $matches)) {
            return intval($matches[1]) + 1; // Convert to 1-indexed
        }

        return null;
    }

    /**
     * Get column information from schema
     */
    protected function getColumnInfo(array $schema, string $field): ?array
    {
        // Try exact match first
        foreach ($schema as $column => $info) {
            if (strcasecmp($column, $field) === 0) {
                return [
                    'header' => $column,
                    'position' => $info['position'],
                    'letter' => $info['letter'],
                ];
            }
        }

        // Try mapping common field names
        $fieldMap = [
            'category' => 'Category',
            'note' => 'Note',
            'notes' => 'Note',
            'tags' => 'Tags',
            'tag' => 'Tags',
        ];

        $mappedField = $fieldMap[strtolower($field)] ?? null;
        if ($mappedField) {
            return $this->getColumnInfo($schema, $mappedField);
        }

        return null;
    }

    /**
     * Check if a column is safe to write to
     */
    protected function isColumnSafe(string $columnHeader): bool
    {
        foreach (self::SAFE_COLUMNS as $safeColumn) {
            if (strcasecmp($columnHeader, $safeColumn) === 0) {
                return true;
            }
        }
        return false;
    }

    /**
     * Check if a cell has a formula
     * This is a simplified check - in production, we'd use the Sheets API
     * to get the actual cell formula
     */
    protected function hasFormula(Sheet $sheet, int $row, string $column): bool
    {
        // For now, assume no formulas in data rows for transaction sheets
        // In production, we'd check the actual cell content
        if ($sheet->sheet_type === 'transactions' && $row > 1) {
            return false;
        }

        // Be cautious with other sheet types
        return $sheet->sheet_type !== 'transactions';
    }

    /**
     * Validate that a value is appropriate for a column
     */
    public function validateValue(string $columnType, $value): bool
    {
        switch ($columnType) {
            case 'date':
                return strtotime($value) !== false;

            case 'amount':
            case 'number':
                return is_numeric($value);

            case 'text':
            case 'string':
            default:
                return is_string($value);
        }
    }

    /**
     * Build a composite key for a transaction
     * Used as fallback when no mobile ID is available
     */
    public function buildCompositeKey(array $transaction): string
    {
        $components = [
            $transaction['account'] ?? '',
            $transaction['date'] ?? '',
            $transaction['amount'] ?? '',
            substr($transaction['description'] ?? '', 0, 50),
        ];

        return md5(implode('|', $components));
    }
}