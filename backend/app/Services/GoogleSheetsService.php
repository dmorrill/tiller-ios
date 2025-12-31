<?php

namespace App\Services;

use Google\Client;
use Google\Service\Sheets;
use Google\Service\Sheets\ValueRange;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class GoogleSheetsService
{
    protected Client $client;
    protected Sheets $service;

    public function __construct()
    {
        $this->client = new Client();
        $this->client->setApplicationName(config('app.name'));
        $this->client->setScopes([
            Sheets::SPREADSHEETS,
            Sheets::DRIVE_FILE,
        ]);
        $this->client->setAccessType('offline');
        $this->client->setPrompt('consent');
    }

    /**
     * Set user's access token for API calls
     */
    public function setAccessToken(array $token): void
    {
        $this->client->setAccessToken($token);

        if ($this->client->isAccessTokenExpired()) {
            $this->refreshToken($token);
        }

        $this->service = new Sheets($this->client);
    }

    /**
     * Refresh expired access token
     */
    protected function refreshToken(array $token): array
    {
        if (!isset($token['refresh_token'])) {
            throw new \Exception('No refresh token available');
        }

        $this->client->fetchAccessTokenWithRefreshToken($token['refresh_token']);
        $newToken = $this->client->getAccessToken();

        // Update user's token in database
        // This would be handled by the calling service

        return $newToken;
    }

    /**
     * Get spreadsheet metadata
     */
    public function getSpreadsheet(string $spreadsheetId): \Google\Service\Sheets\Spreadsheet
    {
        return $this->service->spreadsheets->get($spreadsheetId);
    }

    /**
     * Get values from a range
     */
    public function getValues(string $spreadsheetId, string $range): array
    {
        $response = $this->service->spreadsheets_values->get($spreadsheetId, $range);
        return $response->getValues() ?? [];
    }

    /**
     * Update values in a range
     */
    public function updateValues(string $spreadsheetId, string $range, array $values): void
    {
        $body = new ValueRange([
            'values' => $values
        ]);

        $params = [
            'valueInputOption' => 'USER_ENTERED'
        ];

        $this->service->spreadsheets_values->update(
            $spreadsheetId,
            $range,
            $body,
            $params
        );
    }

    /**
     * Append values to a sheet
     */
    public function appendValues(string $spreadsheetId, string $range, array $values): void
    {
        $body = new ValueRange([
            'values' => $values
        ]);

        $params = [
            'valueInputOption' => 'USER_ENTERED',
            'insertDataOption' => 'INSERT_ROWS'
        ];

        $this->service->spreadsheets_values->append(
            $spreadsheetId,
            $range,
            $body,
            $params
        );
    }

    /**
     * Batch get values from multiple ranges
     */
    public function batchGetValues(string $spreadsheetId, array $ranges): array
    {
        $response = $this->service->spreadsheets_values->batchGet(
            $spreadsheetId,
            ['ranges' => $ranges]
        );

        return $response->getValueRanges();
    }

    /**
     * Find a sheet by name pattern
     */
    public function findSheetByName(string $spreadsheetId, string $pattern): ?array
    {
        $spreadsheet = $this->getSpreadsheet($spreadsheetId);

        foreach ($spreadsheet->getSheets() as $sheet) {
            $title = $sheet->getProperties()->getTitle();
            if (stripos($title, $pattern) !== false) {
                return [
                    'sheetId' => $sheet->getProperties()->getSheetId(),
                    'title' => $title,
                    'index' => $sheet->getProperties()->getIndex(),
                    'gridProperties' => $sheet->getProperties()->getGridProperties(),
                ];
            }
        }

        return null;
    }

    /**
     * Get all sheets in a spreadsheet
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
}