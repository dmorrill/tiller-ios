<?php

use App\Models\SheetSchema;
use App\Models\Sheet;

test('schema belongs to sheet', function () {
    $sheet = Sheet::factory()->create();
    $schema = SheetSchema::factory()->create(['sheet_id' => $sheet->id]);
    expect($schema->sheet)->toBeInstanceOf(Sheet::class);
});
