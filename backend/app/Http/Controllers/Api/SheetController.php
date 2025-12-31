<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\GoogleSheetsService;
use App\Services\SheetDetectionService;
use App\Models\Sheet;
use App\Models\SheetSchema;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class SheetController extends Controller
{
    protected GoogleSheetsService $sheetsService;
    protected SheetDetectionService $detectionService;

    public function __construct(
        GoogleSheetsService $sheetsService,
        SheetDetectionService $detectionService
    ) {
        $this->sheetsService = $sheetsService;
        $this->detectionService = $detectionService;
    }

    /**
     * List user's configured sheets
     */
    public function index(Request $request): JsonResponse
    {
        $sheets = $request->user()->sheets()
            ->with('schema')
            ->get()
            ->map(function ($sheet) {
                return [
                    'id' => $sheet->id,
                    'spreadsheet_id' => $sheet->spreadsheet_id,
                    'sheet_name' => $sheet->sheet_name,
                    'sheet_type' => $sheet->sheet_type,
                    'last_synced_at' => $sheet->last_synced_at,
                    'schema_version' => $sheet->schema_version,
                    'has_mobile_id_column' => $sheet->schema->has_mobile_id_column ?? false,
                ];
            });

        return response()->json(['sheets' => $sheets]);
    }

    /**
     * Auto-detect Tiller sheets in a spreadsheet
     */
    public function detect(Request $request): JsonResponse
    {
        $request->validate([
            'spreadsheet_id' => 'required|string',
        ]);

        try {
            $user = $request->user();

            // Set up Google Sheets service
            $this->sheetsService->setAccessToken([
                'access_token' => $user->google_token,
                'refresh_token' => $user->google_refresh_token,
            ]);

            // Detect Tiller sheets
            $candidates = $this->detectionService->detectTillerSheets(
                $request->input('spreadsheet_id')
            );

            return response()->json([
                'candidates' => $candidates,
                'message' => count($candidates) > 0
                    ? 'Found ' . count($candidates) . ' potential Tiller sheets'
                    : 'No Tiller sheets detected. Please select a sheet manually.',
            ]);

        } catch (\Exception $e) {
            Log::error('Sheet detection error: ' . $e->getMessage());
            return response()->json([
                'error' => 'Failed to detect sheets',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get a specific sheet with its schema
     */
    public function show(Request $request, Sheet $sheet): JsonResponse
    {
        // Ensure user owns the sheet
        if ($sheet->user_id !== $request->user()->id) {
            return response()->json(['error' => 'Sheet not found'], 404);
        }

        $sheet->load('schema');

        return response()->json([
            'sheet' => [
                'id' => $sheet->id,
                'spreadsheet_id' => $sheet->spreadsheet_id,
                'sheet_name' => $sheet->sheet_name,
                'sheet_type' => $sheet->sheet_type,
                'last_synced_at' => $sheet->last_synced_at,
                'schema' => [
                    'columns' => json_decode($sheet->schema->columns ?? '{}', true),
                    'detected_template' => $sheet->schema->detected_template ?? null,
                    'has_mobile_id_column' => $sheet->schema->has_mobile_id_column ?? false,
                ],
            ]
        ]);
    }

    /**
     * Configure a sheet for use with the app
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'spreadsheet_id' => 'required|string',
            'sheet_name' => 'required|string',
            'sheet_type' => 'required|in:transactions,categories,balances,budget',
        ]);

        DB::beginTransaction();

        try {
            $user = $request->user();

            // Set up Google Sheets service
            $this->sheetsService->setAccessToken([
                'access_token' => $user->google_token,
                'refresh_token' => $user->google_refresh_token,
            ]);

            // Detect schema
            $schema = $this->detectionService->detectSchema(
                $request->input('spreadsheet_id'),
                $request->input('sheet_name')
            );

            // Validate schema for transaction sheets
            if ($request->input('sheet_type') === 'transactions') {
                if (!$this->detectionService->validateTransactionSheet($schema)) {
                    return response()->json([
                        'error' => 'Invalid transaction sheet',
                        'message' => 'Sheet must have Date, Amount, and Description columns',
                    ], 400);
                }
            }

            // Create or update sheet configuration
            $sheet = Sheet::updateOrCreate(
                [
                    'user_id' => $user->id,
                    'spreadsheet_id' => $request->input('spreadsheet_id'),
                    'sheet_name' => $request->input('sheet_name'),
                ],
                [
                    'sheet_type' => $request->input('sheet_type'),
                    'schema_version' => 1,
                    'last_synced_at' => now(),
                ]
            );

            // Save schema
            SheetSchema::updateOrCreate(
                ['sheet_id' => $sheet->id],
                [
                    'columns' => json_encode($schema['columns']),
                    'detected_template' => $schema['template'],
                    'has_mobile_id_column' => false, // Will be set when ID column is added
                ]
            );

            DB::commit();

            return response()->json([
                'message' => 'Sheet configured successfully',
                'sheet' => [
                    'id' => $sheet->id,
                    'sheet_type' => $sheet->sheet_type,
                    'columns' => array_keys($schema['columns']),
                ]
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Error configuring sheet: ' . $e->getMessage());
            return response()->json([
                'error' => 'Failed to configure sheet',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update schema mapping for a sheet
     */
    public function updateSchema(Request $request, Sheet $sheet): JsonResponse
    {
        // Ensure user owns the sheet
        if ($sheet->user_id !== $request->user()->id) {
            return response()->json(['error' => 'Sheet not found'], 404);
        }

        $request->validate([
            'column_mappings' => 'required|array',
        ]);

        try {
            $sheet->schema->update([
                'columns' => json_encode($request->input('column_mappings')),
            ]);

            $sheet->increment('schema_version');

            return response()->json([
                'message' => 'Schema updated successfully',
                'schema_version' => $sheet->schema_version,
            ]);

        } catch (\Exception $e) {
            Log::error('Error updating schema: ' . $e->getMessage());
            return response()->json([
                'error' => 'Failed to update schema',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Add mobile ID column to sheet
     */
    public function addMobileIdColumn(Request $request, Sheet $sheet): JsonResponse
    {
        // Ensure user owns the sheet
        if ($sheet->user_id !== $request->user()->id) {
            return response()->json(['error' => 'Sheet not found'], 404);
        }

        try {
            $user = $request->user();

            // Set up Google Sheets service
            $this->sheetsService->setAccessToken([
                'access_token' => $user->google_token,
                'refresh_token' => $user->google_refresh_token,
            ]);

            // Check if column already exists
            if ($sheet->schema->has_mobile_id_column) {
                return response()->json([
                    'message' => 'Mobile ID column already exists',
                ]);
            }

            // Add column header
            $range = "{$sheet->sheet_name}!1:1";
            $headers = $this->sheetsService->getValues($sheet->spreadsheet_id, $range);

            if (!empty($headers[0])) {
                $newColumnIndex = count($headers[0]);
                $columnLetter = $this->numberToColumn($newColumnIndex + 1);

                // Add header
                $this->sheetsService->updateValues(
                    $sheet->spreadsheet_id,
                    "{$sheet->sheet_name}!{$columnLetter}1",
                    [['__mobile_app_id']]
                );

                // Generate IDs for existing rows
                $dataRange = "{$sheet->sheet_name}!A2:Z";
                $existingData = $this->sheetsService->getValues($sheet->spreadsheet_id, $dataRange);

                if (!empty($existingData)) {
                    $ids = [];
                    foreach ($existingData as $index => $row) {
                        $ids[] = [\Illuminate\Support\Str::uuid()->toString()];
                    }

                    $this->sheetsService->updateValues(
                        $sheet->spreadsheet_id,
                        "{$sheet->sheet_name}!{$columnLetter}2",
                        $ids
                    );
                }

                // Update schema
                $sheet->schema->update([
                    'has_mobile_id_column' => true,
                ]);

                return response()->json([
                    'message' => 'Mobile ID column added successfully',
                    'column_position' => $columnLetter,
                ]);
            }

        } catch (\Exception $e) {
            Log::error('Error adding mobile ID column: ' . $e->getMessage());
            return response()->json([
                'error' => 'Failed to add mobile ID column',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Delete a sheet configuration
     */
    public function destroy(Request $request, Sheet $sheet): JsonResponse
    {
        // Ensure user owns the sheet
        if ($sheet->user_id !== $request->user()->id) {
            return response()->json(['error' => 'Sheet not found'], 404);
        }

        try {
            $sheet->schema()->delete();
            $sheet->delete();

            return response()->json([
                'message' => 'Sheet configuration removed successfully',
            ]);

        } catch (\Exception $e) {
            Log::error('Error deleting sheet: ' . $e->getMessage());
            return response()->json([
                'error' => 'Failed to delete sheet configuration',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Convert column number to letter
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
}