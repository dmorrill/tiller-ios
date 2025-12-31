<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Sheet extends Model
{
    protected $fillable = [
        'user_id',
        'spreadsheet_id',
        'sheet_name',
        'sheet_type',
        'last_synced_at',
        'schema_version',
    ];

    protected $casts = [
        'last_synced_at' => 'datetime',
        'schema_version' => 'integer',
    ];

    /**
     * Get the user that owns the sheet.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the schema for the sheet.
     */
    public function schema(): HasOne
    {
        return $this->hasOne(SheetSchema::class);
    }
}
