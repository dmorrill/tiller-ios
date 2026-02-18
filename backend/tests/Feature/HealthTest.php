<?php

test('health endpoint returns ok', function () {
    $response = $this->getJson('/api/health');
    $response->assertStatus(200);
    $response->assertJsonStructure(['status', 'timestamp']);
});
