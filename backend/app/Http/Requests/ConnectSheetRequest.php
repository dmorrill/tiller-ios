<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ConnectSheetRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'spreadsheet_url' => [
                'required',
                'string',
                'url',
                'regex:#https://docs\.google\.com/spreadsheets/d/([a-zA-Z0-9_-]+)#',
            ],
        ];
    }

    public function messages(): array
    {
        return [
            'spreadsheet_url.regex' => 'Please provide a valid Google Sheets URL.',
        ];
    }

    /**
     * Extract spreadsheet ID from the URL.
     */
    public function spreadsheetId(): string
    {
        preg_match('#/spreadsheets/d/([a-zA-Z0-9_-]+)#', $this->input('spreadsheet_url'), $matches);
        return $matches[1];
    }
}
