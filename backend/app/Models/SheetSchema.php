<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SheetSchema extends Model
{
    protected $fillable = [
        'sheet_id',
        'schema_type',
        'column_mappings',
        'detected_at',
    ];

    protected $casts = [
        'column_mappings' => 'array',
        'detected_at' => 'datetime',
    ];

    /**
     * Get the sheet that owns the schema.
     */
    public function sheet(): BelongsTo
    {
        return $this->belongsTo(Sheet::class);
    }
}
