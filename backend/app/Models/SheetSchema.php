<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SheetSchema extends Model
{
    protected $fillable = [
        'sheet_id',
        'columns',
        'detected_template',
        'has_mobile_id_column',
    ];

    protected $casts = [
        'columns' => 'array',
        'has_mobile_id_column' => 'boolean',
    ];

    /**
     * Get the sheet that owns the schema.
     */
    public function sheet(): BelongsTo
    {
        return $this->belongsTo(Sheet::class);
    }
}
