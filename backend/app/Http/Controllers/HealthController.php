<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class HealthController extends Controller
{
    public function __invoke(): JsonResponse
    {
        try { DB::connection()->getPdo(); $ok = true; } catch (\Exception $e) { $ok = false; }
        return response()->json(['status' => $ok ? 'healthy' : 'degraded', 'timestamp' => now()->toIso8601String()], $ok ? 200 : 503);
    }
}
