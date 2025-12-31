<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('sheets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('spreadsheet_id');
            $table->string('sheet_name');
            $table->enum('sheet_type', ['transactions', 'categories', 'balances', 'budget']);
            $table->timestamp('last_synced_at')->nullable();
            $table->integer('schema_version')->default(1);
            $table->timestamps();

            $table->index(['user_id', 'spreadsheet_id']);
            $table->unique(['user_id', 'spreadsheet_id', 'sheet_name']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('sheets');
    }
};
