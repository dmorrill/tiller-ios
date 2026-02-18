<?php

test('health endpoint returns ok', function () {
    $response = $this->getJson('/up');
    $response->assertStatus(200);
});
