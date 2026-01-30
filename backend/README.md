# WYSC Backend API

Lightweight Flask service that exposes read/write endpoints backed by your Supabase project. The goal is to keep the codebase approachable while following clean, well-documented practices.

## Features
- Flask 2.x application scaffolded for quick iteration
- Supabase Python SDK wired in with cached client creation
- JSON-first routes for listing and inserting table rows
- Simple health checks for both the API and the Supabase connection

## Tech Stack
- Python 3.10+
- Flask
- Supabase Python SDK

## Prerequisites
1. Python 3.10 or later installed on your machine
2. Supabase project with at least one table (default: `profiles`)
3. Git / VS Code optional but recommended

## Getting Started
```bash
cd backend
python -m venv .venv
. .venv/Scripts/activate    # PowerShell: .venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

## Environment Variables
The API expects credentials exposed as environment variables. A starter `.env` file is included in this folder:

```
SUPABASE_URL="https://YOUR-PROJECT-ref.supabase.co"
SUPABASE_ANON_KEY="YOUR-ANON-KEY"
SUPABASE_TABLE="profiles"
```

Load them with your preferred workflow:
- `flask --app app.py run --env-file .env --debug`
- or `pip install python-dotenv` and use `python -m flask --app app.py run`
- or export the variables directly in your shell profile/CI platform

## Run the API
```bash
flask --app app.py run --debug
```

Visit `http://127.0.0.1:5000` to confirm the service is up.

## API Endpoints
| Method | Route              | Description                                 |
| ------ | ------------------ | ------------------------------------------- |
| GET    | `/`                | Basic welcome payload                       |
| GET    | `/health`          | Application health probe                    |
| GET    | `/supabase/health` | Verifies Supabase credentials/client status |
| GET    | `/records`         | Returns up to 100 rows from `SUPABASE_TABLE`|
| POST   | `/records`         | Inserts JSON payload into `SUPABASE_TABLE`  |

## Connecting to Supabase
1. In the Supabase dashboard grab the Project URL and anon/public API key.
2. Paste the values into `.env` or your secret manager.
3. Set `SUPABASE_TABLE` to the table you want to expose (create it first if needed).
4. Hit `GET /supabase/health` to confirm the SDK can authenticate.
5. Use the `GET/POST /records` routes to fetch or insert rows.

## Troubleshooting
- Missing credentials: `/supabase/health` will return `error`; double-check `.env`.
- Validation errors: the POST route accepts JSON only—ensure the `Content-Type` header is `application/json`.
- Supabase schema mismatches: if inserts fail, confirm the payload matches column names and types in your target table.

## Next Steps
- Add authentication (JWT/Auth0/Supabase Auth) before exposing the endpoints publicly.
- Create additional CRUD routes per table or abstract logic into service modules for larger projects.
