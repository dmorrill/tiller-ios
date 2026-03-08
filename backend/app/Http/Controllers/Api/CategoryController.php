<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\GoogleSheetsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class CategoryController extends Controller
{
    protected const FALLBACK_CATEGORIES = [
        'Auto & Transport', 'Bills & Utilities', 'Business Services',
        'Education', 'Entertainment', 'Fees & Charges', 'Food & Dining',
        'Gifts & Donations', 'Health & Fitness', 'Home', 'Income',
        'Investments', 'Kids', 'Personal Care', 'Pets', 'Shopping',
        'Taxes', 'Transfer', 'Travel', 'Uncategorized',
    ];

    public function __construct(
        protected GoogleSheetsService $sheetsService,
    ) {}

    /**
     * Get categories from connected sheet, or fallback to defaults.
     */
    public function index(Request $request): JsonResponse
    {
        $sheet = $request->user()->sheets()->first();

        if (!$sheet || !$sheet->schema) {
            return response()->json(['categories' => self::FALLBACK_CATEGORIES]);
        }

        try {
            $mappings = $sheet->schema->column_mappings;
            $catColumn = $mappings['categories']['Category'] ?? null;

            if ($catColumn === null) {
                return response()->json(['categories' => self::FALLBACK_CATEGORIES]);
            }

            $this->sheetsService->authenticateServiceAccount();
            $rows = $this->sheetsService->getValues($sheet->spreadsheet_id, 'Categories!A:Z');

            if (empty($rows) || count($rows) < 2) {
                return response()->json(['categories' => self::FALLBACK_CATEGORIES]);
            }

            // Skip header row, extract category names
            $categories = [];
            foreach (array_slice($rows, 1) as $row) {
                $name = trim($row[$catColumn] ?? '');
                if ($name !== '') {
                    $categories[] = $name;
                }
            }

            return response()->json(['categories' => $categories ?: self::FALLBACK_CATEGORIES]);

        } catch (\Exception $e) {
            Log::warning('Failed to read categories from sheet: ' . $e->getMessage());
            return response()->json(['categories' => self::FALLBACK_CATEGORIES]);
        }
    }
}
