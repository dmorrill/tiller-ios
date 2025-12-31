<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Google\Client as GoogleClient;
use Illuminate\Http\JsonResponse;

class AuthController extends Controller
{
    protected GoogleClient $googleClient;

    public function __construct()
    {
        $this->googleClient = new GoogleClient();
        $this->googleClient->setClientId(config('services.google.client_id'));
        $this->googleClient->setClientSecret(config('services.google.client_secret'));
        $this->googleClient->setRedirectUri(config('services.google.redirect'));
        $this->googleClient->addScope('email');
        $this->googleClient->addScope('profile');
        $this->googleClient->addScope('https://www.googleapis.com/auth/spreadsheets');
        $this->googleClient->addScope('https://www.googleapis.com/auth/drive.file');
        $this->googleClient->setAccessType('offline');
        $this->googleClient->setPrompt('consent'); // Force to get refresh token
    }

    /**
     * Redirect to Google OAuth
     */
    public function redirectToGoogle(): JsonResponse
    {
        $authUrl = $this->googleClient->createAuthUrl();

        return response()->json([
            'auth_url' => $authUrl
        ]);
    }

    /**
     * Handle Google OAuth callback
     */
    public function handleGoogleCallback(Request $request): JsonResponse
    {
        try {
            $code = $request->input('code');

            if (!$code) {
                return response()->json(['error' => 'Authorization code not provided'], 400);
            }

            // Exchange code for tokens
            $token = $this->googleClient->fetchAccessTokenWithAuthCode($code);

            if (isset($token['error'])) {
                return response()->json(['error' => $token['error']], 400);
            }

            $this->googleClient->setAccessToken($token);

            // Get user info from Google
            $googleService = new \Google\Service\Oauth2($this->googleClient);
            $googleUser = $googleService->userinfo->get();

            // Create or update user
            $user = User::updateOrCreate(
                ['google_id' => $googleUser->id],
                [
                    'name' => $googleUser->name,
                    'email' => $googleUser->email,
                    'google_token' => $token['access_token'],
                    'google_refresh_token' => $token['refresh_token'] ?? null,
                    'google_token_expires_at' => now()->addSeconds($token['expires_in']),
                    'avatar' => $googleUser->picture,
                ]
            );

            // Create Sanctum token for API access
            $authToken = $user->createToken('auth-token')->plainTextToken;

            return response()->json([
                'user' => $user,
                'access_token' => $authToken,
                'token_type' => 'Bearer',
            ]);

        } catch (\Exception $e) {
            Log::error('Google OAuth error: ' . $e->getMessage());
            return response()->json([
                'error' => 'Authentication failed',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mobile app authentication flow
     * The iOS app will send the Google auth code directly
     */
    public function mobileAuth(Request $request): JsonResponse
    {
        $request->validate([
            'auth_code' => 'required|string',
        ]);

        try {
            // Exchange code for tokens
            $token = $this->googleClient->fetchAccessTokenWithAuthCode($request->auth_code);

            if (isset($token['error'])) {
                return response()->json(['error' => $token['error']], 400);
            }

            $this->googleClient->setAccessToken($token);

            // Get user info
            $googleService = new \Google\Service\Oauth2($this->googleClient);
            $googleUser = $googleService->userinfo->get();

            // Create or update user
            $user = User::updateOrCreate(
                ['google_id' => $googleUser->id],
                [
                    'name' => $googleUser->name,
                    'email' => $googleUser->email,
                    'google_token' => $token['access_token'],
                    'google_refresh_token' => $token['refresh_token'] ?? null,
                    'google_token_expires_at' => now()->addSeconds($token['expires_in']),
                    'avatar' => $googleUser->picture,
                ]
            );

            // Create Sanctum token
            $authToken = $user->createToken('mobile-app')->plainTextToken;

            return response()->json([
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'avatar' => $user->avatar,
                ],
                'access_token' => $authToken,
                'token_type' => 'Bearer',
            ]);

        } catch (\Exception $e) {
            Log::error('Mobile auth error: ' . $e->getMessage());
            return response()->json([
                'error' => 'Authentication failed',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Refresh access token
     */
    public function refreshToken(Request $request): JsonResponse
    {
        try {
            $user = $request->user();

            if (!$user->google_refresh_token) {
                return response()->json(['error' => 'No refresh token available'], 400);
            }

            $this->googleClient->refreshToken($user->google_refresh_token);
            $newToken = $this->googleClient->getAccessToken();

            // Update user's tokens
            $user->update([
                'google_token' => $newToken['access_token'],
                'google_token_expires_at' => now()->addSeconds($newToken['expires_in']),
            ]);

            return response()->json([
                'access_token' => $newToken['access_token'],
                'expires_in' => $newToken['expires_in'],
            ]);

        } catch (\Exception $e) {
            Log::error('Token refresh error: ' . $e->getMessage());
            return response()->json([
                'error' => 'Failed to refresh token',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get authenticated user
     */
    public function user(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'avatar' => $user->avatar,
            'has_refresh_token' => !empty($user->google_refresh_token),
        ]);
    }

    /**
     * Logout user (revoke tokens)
     */
    public function logout(Request $request): JsonResponse
    {
        try {
            // Revoke current access token
            $request->user()->currentAccessToken()->delete();

            // Optionally revoke all tokens
            // $request->user()->tokens()->delete();

            return response()->json([
                'message' => 'Successfully logged out'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Logout failed',
                'message' => $e->getMessage()
            ], 500);
        }
    }
}