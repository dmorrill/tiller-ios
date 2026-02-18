<?php

namespace Database\Factories;

use App\Models\Sheet;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class SheetFactory extends Factory
{
    protected $model = Sheet::class;

    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'name' => $this->faker->randomElement(['Budget', 'Savings', 'Investments', 'Expenses']),
            'type' => 'spreadsheet',
        ];
    }
}
