<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\SheetController;
use App\Http\Controllers\Api\TransactionController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\SyncController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group.
|
*/

// Public routes (no authentication required)
Route::prefix('auth')->group(function () {
    Route::get('google', [AuthController::class, 'redirectToGoogle']);
    Route::get('google/callback', [AuthController::class, 'handleGoogleCallback']);
    Route::post('mobile', [AuthController::class, 'mobileAuth']);
});

// Protected routes (require authentication)
Route::middleware('auth:sanctum')->group(function () {
    // Authentication
    Route::prefix('auth')->group(function () {
        Route::get('user', [AuthController::class, 'user']);
        Route::post('refresh', [AuthController::class, 'refreshToken']);
        Route::post('logout', [AuthController::class, 'logout']);
    });

    // Sheet Management
    Route::prefix('sheets')->group(function () {
        Route::get('/', [SheetController::class, 'index']);
        Route::post('detect', [SheetController::class, 'detect']);
        Route::post('/', [SheetController::class, 'store']);
        Route::get('{sheet}', [SheetController::class, 'show']);
        Route::put('{sheet}/schema', [SheetController::class, 'updateSchema']);
        Route::post('{sheet}/mobile-id', [SheetController::class, 'addMobileIdColumn']);
        Route::delete('{sheet}', [SheetController::class, 'destroy']);
    });

    // Transactions
    Route::prefix('transactions')->group(function () {
        Route::get('/', [TransactionController::class, 'index']);
        Route::post('/', [TransactionController::class, 'store']);
        Route::get('{id}', [TransactionController::class, 'show']);
        Route::patch('{id}', [TransactionController::class, 'update']);
    });

    // Categories (to be implemented)
    Route::prefix('categories')->group(function () {
        Route::get('/', function () {
            return response()->json(['categories' => [
                'Auto & Transport',
                'Bills & Utilities',
                'Business Services',
                'Education',
                'Entertainment',
                'Fees & Charges',
                'Food & Dining',
                'Gifts & Donations',
                'Health & Fitness',
                'Home',
                'Income',
                'Investments',
                'Kids',
                'Personal Care',
                'Pets',
                'Shopping',
                'Taxes',
                'Transfer',
                'Travel',
                'Uncategorized'
            ]]);
        });
    });

    // Sync Operations (to be implemented)
    Route::prefix('sync')->group(function () {
        Route::post('transactions', function () {
            return response()->json(['message' => 'Sync initiated']);
        });
        Route::get('status', function () {
            return response()->json(['status' => 'idle']);
        });
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