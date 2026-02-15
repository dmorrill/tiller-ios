<?php

namespace App\Services;

use Google\Client;
use Google\Service\Sheets;
use Google\Service\Sheets\ValueRange;
use Illuminate\Support\Facades\Log;

class GoogleSheetsService
{
    protected Client $client;
    protected ?Sheets $service = null;

    public function __construct()
    {
        $this->client = new Client();
        $this->client->setApplicationName(config('app.name'));
        $this->client->setScopes([
            Sheets::SPREADSHEETS,
            Sheets::DRIVE_FILE,
        ]);
    }

    /**
     * Authenticate using a service account JSON key file.
     */
    public function authenticateServiceAccount(): void
    {
        $keyPath = config('services.google.service_account_key_path');

        if (!$keyPath || !file_exists($keyPath)) {
            throw new \RuntimeException('Service account key file not found at: ' . ($keyPath ?: '(not configured)'));
        }

        $this->client->setAuthConfig($keyPath);
        $this->service = new Sheets($this->client);
    }

    /**
     * Set user's OAuth access token (legacy support).
     */
    public function setAccessToken(array $token): void
    {
        $this->client->setAccessToken($token);

        if ($this->client->isAccessTokenExpired() && isset($token['refresh_token'])) {
            $this->client->fetchAccessTokenWithRefreshToken($token['refresh_token']);
        }

        $this->service = new Sheets($this->client);
    }

    /**
     * Get spreadsheet metadata.
     */
    public function getSpreadsheet(string $spreadsheetId): \Google\Service\Sheets\Spreadsheet
    {
        $this->ensureService();
        return $this->service->spreadsheets->get($spreadsheetId);
    }

    /**
     * Get values from a range.
     */
    public function getValues(string $spreadsheetId, string $range): array
    {
        $this->ensureService();
        $response = $this->service->spreadsheets_values->get($spreadsheetId, $range);
        return $response->getValues() ?? [];
    }

    /**
     * Update values in a range.
     */
    public function updateValues(string $spreadsheetId, string $range, array $values): void
    {
        $this->ensureService();
        $body = new ValueRange(['values' => $values]);
        $this->service->spreadsheets_values->update(
            $spreadsheetId, $range, $body,
            ['valueInputOption' => 'USER_ENTERED']
        );
    }

    /**
     * Append values to a sheet.
     */
    public function appendValues(string $spreadsheetId, string $range, array $values): void
    {
        $this->ensureService();
        $body = new ValueRange(['values' => $values]);
        $this->service->spreadsheets_values->append(
            $spreadsheetId, $range, $body,
            ['valueInputOption' => 'USER_ENTERED', 'insertDataOption' => 'INSERT_ROWS']
        );
    }

    /**
     * Get all sheets in a spreadsheet.
     */
    public function getAllSheets(string $spreadsheetId): array
    {
        $spreadsheet = $this->getSpreadsheet($spreadsheetId);
        $sheets = [];

        foreach ($spreadsheet->getSheets() as $sheet) {
            $sheets[] = [
                'sheetId' => $sheet->getProperties()->getSheetId(),
                'title' => $sheet->getProperties()->getTitle(),
                'index' => $sheet->getProperties()->getIndex(),
            ];
        }

        return $sheets;
    }

    private function ensureService(): void
    {
        if (!$this->service) {
            throw new \RuntimeException('Google Sheets service not initialized. Call authenticateServiceAccount() or setAccessToken() first.');
        }
    }
}
