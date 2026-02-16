<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\SheetController;
use App\Http\Controllers\Api\TransactionController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Health check
Route::get('health', fn () => response()->json(['status' => 'ok', 'timestamp' => now()->toIso8601String()]));

// Public auth routes
Route::prefix('auth')->group(function () {
    Route::post('register', [AuthController::class, 'register']);
    Route::post('login', [AuthController::class, 'login']);
});

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    // Auth
    Route::prefix('auth')->group(function () {
        Route::get('user', [AuthController::class, 'user']);
        Route::post('logout', [AuthController::class, 'logout']);
    });

    // Sheets
    Route::prefix('sheets')->group(function () {
        Route::get('/', [SheetController::class, 'index']);
        Route::post('connect', [SheetController::class, 'connect']);
        Route::get('service-account', [SheetController::class, 'serviceAccountEmail']);
        Route::delete('{sheet}', [SheetController::class, 'destroy']);
    });

    // Transactions
    Route::prefix('transactions')->group(function () {
        Route::get('/', [TransactionController::class, 'index']);
        Route::post('/', [TransactionController::class, 'store']);
        Route::get('{id}', [TransactionController::class, 'show']);
        Route::patch('{id}', [TransactionController::class, 'update']);
    });

    // Categories
    Route::get('categories', function () {
        return response()->json(['categories' => [
            'Auto & Transport', 'Bills & Utilities', 'Business Services',
            'Education', 'Entertainment', 'Fees & Charges', 'Food & Dining',
            'Gifts & Donations', 'Health & Fitness', 'Home', 'Income',
            'Investments', 'Kids', 'Personal Care', 'Pets', 'Shopping',
            'Taxes', 'Transfer', 'Travel', 'Uncategorized',
        ]]);
    });
});

// Health check
Route::get('health', function () {
    return response()->json([
        'status' => 'healthy',
        'version' => '1.0.0',
        'timestamp' => now()->toIso8601String(),
    ]);
});
