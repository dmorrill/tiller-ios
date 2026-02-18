<?php

use App\Models\User;

test('login page loads', function () {
    $response = $this->get('/login');
    $response->assertStatus(200);
});

test('user can register', function () {
    $response = $this->post('/register', [
        'name' => 'Test User',
        'email' => 'test@example.com',
        'password' => 'password123',
        'password_confirmation' => 'password123',
    ]);
    $response->assertRedirect();
});
