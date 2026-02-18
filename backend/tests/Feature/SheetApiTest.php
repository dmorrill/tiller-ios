<?php

use App\Models\User;
use App\Models\Sheet;
use Laravel\Sanctum\Sanctum;

test('sheets require authentication', function () {
    $response = $this->getJson('/api/sheets');
    $response->assertStatus(401);
});

test('authenticated user can list sheets', function () {
    $user = User::factory()->create();
    Sanctum::actingAs($user);
    Sheet::factory()->count(3)->create(['user_id' => $user->id]);

    $response = $this->getJson('/api/sheets');
    $response->assertStatus(200);
});
