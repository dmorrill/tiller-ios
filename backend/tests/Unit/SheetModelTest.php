<?php

use App\Models\Sheet;
use App\Models\User;

test('sheet belongs to a user', function () {
    $user = User::factory()->create();
    $sheet = Sheet::factory()->create(['user_id' => $user->id]);
    expect($sheet->user)->toBeInstanceOf(User::class);
});

test('sheet has a name', function () {
    $sheet = Sheet::factory()->create(['name' => 'Morning Routine']);
    expect($sheet->name)->toBe('Morning Routine');
});
