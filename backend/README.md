# Tiller Backend

Laravel API backend for the Tiller habit tracking app.

## Setup

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan serve
```

## Testing

```bash
php artisan test
```

## API Endpoints

- `GET /api/sheets` — List user's sheets
- `POST /api/sheets` — Create a sheet
- `GET /api/sheets/{id}` — Get sheet details
- `PUT /api/sheets/{id}` — Update sheet
- `DELETE /api/sheets/{id}` — Delete sheet

## Authentication

Google OAuth via Laravel Socialite. See `setup-google-auth.md`.
