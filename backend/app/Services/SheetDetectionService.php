<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;

class SheetDetectionService
{
    protected GoogleSheetsService $sheetsService;

    // Tiller signature columns
    const TILLER_SIGNATURE_COLUMNS = [
        'Date',
        'Description',
        'Amount',
        'Account',
        'Category'
    ];

    // Common Tiller sheet names
    const TILLER_SHEET_PATTERNS = [
        'Transactions',
        'Categories',
        'Balances',
        'Register',
        'Tiller'
    ];

    public function __construct(GoogleSheetsService $sheetsService)
    {
        $this->sheetsService = $sheetsService;
    }

    /**
     * Detect Tiller sheets in a spreadsheet
     */
    public function detectTillerSheets(string $spreadsheetId): array
    {
        $candidates = [];
        $sheets = $this->sheetsService->getAllSheets($spreadsheetId);

        foreach ($sheets as $sheet) {
            $confidence = $this->calculateConfidence($spreadsheetId, $sheet['title']);

            if ($confidence > 0) {
                $candidates[] = [
                    'sheet' => $sheet,
                    'confidence' => $confidence,
                    'type' => $this->detectSheetType($spreadsheetId, $sheet['title']),
                ];
            }
        }

        // Sort by confidence
        usort($candidates, fn($a, $b) => $b['confidence'] <=> $a['confidence']);

        return $candidates;
    }

    /**
     * Calculate confidence score for a sheet being a Tiller sheet
     */
    protected function calculateConfidence(string $spreadsheetId, string $sheetName): int
    {
        $confidence = 0;

        // Check sheet name patterns
        foreach (self::TILLER_SHEET_PATTERNS as $pattern) {
            if (stripos($sheetName, $pattern) !== false) {
                $confidence += 30;
                break;
            }
        }

        // Check for signature columns
        try {
            $headers = $this->sheetsService->getValues($spreadsheetId, "{$sheetName}!1:1");
            if (!empty($headers[0])) {
                $headerRow = array_map('strtolower', $headers[0]);
                $signatureColumns = array_map('strtolower', self::TILLER_SIGNATURE_COLUMNS);

                $matchCount = 0;
                foreach ($signatureColumns as $column) {
                    if (in_array($column, $headerRow)) {
                        $matchCount++;
                    }
                }

                // Add confidence based on matching columns
                $confidence += ($matchCount / count($signatureColumns)) * 70;
            }
        } catch (\Exception $e) {
            Log::warning("Could not read headers from sheet {$sheetName}: " . $e->getMessage());
        }

        return (int) $confidence;
    }

    /**
     * Detect the type of Tiller sheet
     */
    protected function detectSheetType(string $spreadsheetId, string $sheetName): string
    {
        $nameLower = strtolower($sheetName);

        if (strpos($nameLower, 'transaction') !== false) {
            return 'transactions';
        }
        if (strpos($nameLower, 'categor') !== false) {
            return 'categories';
        }
        if (strpos($nameLower, 'balance') !== false) {
            return 'balances';
        }
        if (strpos($nameLower, 'budget') !== false) {
            return 'budget';
        }

        // Check by columns if name doesn't match
        try {
            $headers = $this->sheetsService->getValues($spreadsheetId, "{$sheetName}!1:1");
            if (!empty($headers[0])) {
                $headerRow = array_map('strtolower', $headers[0]);

                // Transaction sheet indicators
                if (in_array('date', $headerRow) && in_array('amount', $headerRow)) {
                    return 'transactions';
                }

                // Category sheet indicators
                if (in_array('category', $headerRow) && in_array('group', $headerRow)) {
                    return 'categories';
                }

                // Balance sheet indicators
                if (in_array('account', $headerRow) && in_array('balance', $headerRow)) {
                    return 'balances';
                }
            }
        } catch (\Exception $e) {
            Log::warning("Could not detect sheet type for {$sheetName}: " . $e->getMessage());
        }

        return 'unknown';
    }

    /**
     * Detect and map column positions for a sheet
     */
    public function detectSchema(string $spreadsheetId, string $sheetName): array
    {
        $schema = [
            'sheetName' => $sheetName,
            'columns' => [],
            'template' => null,
            'hasFormulas' => false,
        ];

        try {
            // Get headers
            $headers = $this->sheetsService->getValues($spreadsheetId, "{$sheetName}!1:1");
            if (empty($headers[0])) {
                return $schema;
            }

            // Map column positions
            foreach ($headers[0] as $index => $header) {
                $columnLetter = $this->numberToColumn($index + 1);
                $schema['columns'][$header] = [
                    'position' => $index,
                    'letter' => $columnLetter,
                    'header' => $header,
                ];
            }

            // Detect template type
            $schema['template'] = $this->detectTemplateType($schema['columns']);

            // Check for formulas in first data row
            $schema['hasFormulas'] = $this->checkForFormulas($spreadsheetId, $sheetName);

        } catch (\Exception $e) {
            Log::error("Error detecting schema for {$sheetName}: " . $e->getMessage());
        }

        return $schema;
    }

    /**
     * Detect Tiller template type based on columns
     */
    protected function detectTemplateType(array $columns): string
    {
        $columnNames = array_keys($columns);

        // Foundation Template indicators
        if (in_array('Month', $columnNames) || in_array('Week', $columnNames)) {
            return 'foundation';
        }

        // Budget Template indicators
        if (in_array('Budget', $columnNames) || in_array('Available', $columnNames)) {
            return 'budget';
        }

        // Basic template
        if (count(array_intersect($columnNames, self::TILLER_SIGNATURE_COLUMNS)) >= 3) {
            return 'basic';
        }

        return 'custom';
    }

    /**
     * Check if sheet has formulas (simplified check)
     */
    protected function checkForFormulas(string $spreadsheetId, string $sheetName): bool
    {
        // For now, we'll assume certain columns typically have formulas
        // In production, we'd check actual cell values for formula indicators
        return in_array(strtolower($sheetName), ['balances', 'budget', 'reports']);
    }

    /**
     * Convert column number to letter (1 -> A, 27 -> AA, etc)
     */
    protected function numberToColumn(int $number): string
    {
        $letter = '';
        while ($number > 0) {
            $number--;
            $letter = chr(65 + ($number % 26)) . $letter;
            $number = intval($number / 26);
        }
        return $letter;
    }

    /**
     * Validate that a sheet has required columns for transactions
     */
    public function validateTransactionSheet(array $schema): bool
    {
        $requiredColumns = ['Date', 'Amount', 'Description'];
        $columns = array_keys($schema['columns'] ?? []);

        foreach ($requiredColumns as $required) {
            $found = false;
            foreach ($columns as $column) {
                if (strcasecmp($column, $required) === 0) {
                    $found = true;
                    break;
                }
            }
            if (!$found) {
                return false;
            }
        }

        return true;
    }
}