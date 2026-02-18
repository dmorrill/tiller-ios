<?php

use App\Models\User;
use App\Models\Sheet;

test('user has many sheets', function () {
    $user = User::factory()->create();
    expect($user->sheets())->toBeInstanceOf(\Illuminate\Database\Eloquent\Relations\HasMany::class);
});

test('user email must be unique', function () {
    User::factory()->create(['email' => 'test@example.com']);
    expect(fn () => User::factory()->create(['email' => 'test@example.com']))
        ->toThrow(\Illuminate\Database\QueryException::class);
});
