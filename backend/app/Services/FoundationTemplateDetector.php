<?php

namespace App\Services;

use App\Models\Sheet;
use App\Models\SheetSchema;
use Illuminate\Support\Facades\Log;

class FoundationTemplateDetector
{
    protected const REQUIRED_TRANSACTION_COLUMNS = [
        'Date', 'Description', 'Category', 'Amount', 'Account',
        'Account #', 'Institution', 'Month', 'Week', 'Transaction ID',
        'Check Number', 'Full Description', 'Date Added', 'Categorized Date',
    ];

    protected const REQUIRED_CATEGORY_COLUMNS = [
        'Category', 'Group', 'Type', 'Hide From Reports',
    ];

    public function __construct(
        protected GoogleSheetsService $sheetsService,
    ) {}

    /**
     * Detect Foundation Template schema and store column mappings.
     *
     * @throws \RuntimeException if required columns are missing
     */
    public function detect(Sheet $sheet): array
    {
        $this->sheetsService->authenticateServiceAccount();

        $transactionMappings = $this->detectColumns(
            $sheet->spreadsheet_id,
            'Transactions',
            self::REQUIRED_TRANSACTION_COLUMNS,
        );

        $categoryMappings = $this->detectColumns(
            $sheet->spreadsheet_id,
            'Categories',
            self::REQUIRED_CATEGORY_COLUMNS,
        );

        $mappings = [
            'transactions' => $transactionMappings,
            'categories' => $categoryMappings,
        ];

        // Store in sheet_schemas
        SheetSchema::updateOrCreate(
            ['sheet_id' => $sheet->id],
            [
                'schema_type' => 'foundation',
                'column_mappings' => $mappings,
                'detected_at' => now(),
            ],
        );

        return $mappings;
    }

    /**
     * Read header row and map column names to 0-based positions.
     */
    protected function detectColumns(string $spreadsheetId, string $tabName, array $requiredColumns): array
    {
        $headers = $this->sheetsService->getValues($spreadsheetId, "{$tabName}!1:1");

        if (empty($headers) || empty($headers[0])) {
            throw new \RuntimeException("No headers found in '{$tabName}' tab.");
        }

        $headerRow = array_map('trim', $headers[0]);
        $mappings = [];

        foreach ($headerRow as $index => $header) {
            $mappings[$header] = $index;
        }

        // Validate all required columns exist
        $missing = array_diff($requiredColumns, array_keys($mappings));

        if (!empty($missing)) {
            throw new \RuntimeException(
                "Missing required columns in '{$tabName}': " . implode(', ', $missing)
            );
        }

        return $mappings;
    }
}
