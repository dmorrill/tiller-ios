<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\ConnectSheetRequest;
use App\Models\Sheet;
use App\Services\GoogleSheetsService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;

class SheetController extends Controller
{
    public function __construct(
        protected GoogleSheetsService $sheetsService,
    ) {}

    /**
     * List user's connected sheets.
     */
    public function index(Request $request): JsonResponse
    {
        $sheets = $request->user()->sheets()->get()->map(fn ($sheet) => [
            'id' => $sheet->id,
            'spreadsheet_id' => $sheet->spreadsheet_id,
            'sheet_name' => $sheet->sheet_name,
            'last_synced_at' => $sheet->last_synced_at,
        ]);

        return response()->json(['data' => $sheets]);
    }

    /**
     * Connect a Google Sheet by URL.
     */
    public function connect(ConnectSheetRequest $request): JsonResponse
    {
        $spreadsheetId = $request->spreadsheetId();
        $user = $request->user();

        // Check if already connected
        if ($user->sheets()->where('spreadsheet_id', $spreadsheetId)->exists()) {
            return response()->json([
                'error' => 'Sheet already connected',
                'message' => 'This spreadsheet is already connected to your account.',
            ], 409);
        }

        try {
            // Try to read the spreadsheet using service account to verify access
            $this->sheetsService->authenticateServiceAccount();
            $spreadsheet = $this->sheetsService->getSpreadsheet($spreadsheetId);
            $title = $spreadsheet->getProperties()->getTitle();

            $sheet = $user->sheets()->create([
                'spreadsheet_id' => $spreadsheetId,
                'sheet_name' => $title,
                'sheet_type' => 'transactions',
                'last_synced_at' => now(),
            ]);

            return response()->json([
                'message' => 'Sheet connected successfully',
                'data' => [
                    'id' => $sheet->id,
                    'spreadsheet_id' => $sheet->spreadsheet_id,
                    'sheet_name' => $sheet->sheet_name,
                ],
            ], 201);

        } catch (\Exception $e) {
            Log::error('Sheet connect error: ' . $e->getMessage());
            return response()->json([
                'error' => 'Failed to connect sheet',
                'message' => 'Could not access the spreadsheet. Make sure you shared it with ' . config('services.google.service_account_email'),
            ], 422);
        }
    }

    /**
     * Get the service account email for sharing.
     */
    public function serviceAccountEmail(): JsonResponse
    {
        return response()->json([
            'email' => config('services.google.service_account_email'),
        ]);
    }

    /**
     * Delete a sheet connection.
     */
    public function destroy(Request $request, Sheet $sheet): JsonResponse
    {
        if ($sheet->user_id !== $request->user()->id) {
            return response()->json(['error' => 'Not found'], 404);
        }

        $sheet->schema()?->delete();
        $sheet->delete();

        return response()->json(['message' => 'Sheet disconnected']);
    }
}
