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
        Schema::table('users', function (Blueprint $table) {
            $table->string('google_id')->unique()->nullable()->after('id');
            $table->text('google_token')->nullable()->after('remember_token');
            $table->text('google_refresh_token')->nullable()->after('google_token');
            $table->timestamp('google_token_expires_at')->nullable()->after('google_refresh_token');
            $table->string('avatar')->nullable()->after('email');
            $table->json('settings')->nullable();

            // Make password nullable for Google-only auth
            $table->string('password')->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'google_id',
                'google_token',
                'google_refresh_token',
                'google_token_expires_at',
                'avatar',
                'settings'
            ]);

            // Restore password as required
            $table->string('password')->nullable(false)->change();
        });
    }
};
