<?php

use App\Models\User;
use App\Models\Sheet;

test('sheets require authentication', function () {
    $response = $this->getJson('/api/sheets');
    $response->assertStatus(401);
});

test('user can list their sheets', function () {
    $user = User::factory()->create();
    Sheet::factory()->count(3)->create(['user_id' => $user->id]);

    $response = $this->actingAs($user)->getJson('/api/sheets');
    $response->assertStatus(200);
});
