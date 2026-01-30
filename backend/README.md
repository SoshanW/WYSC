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
- GitHub Copilot SDK

## Prerequisites
1. Python 3.10 or later installed on your machine
2. Supabase project with at least one table (default: `profiles`)
3. GitHub Copilot CLI installed and authenticated (see below)
4. Git / VS Code optional but recommended

## Setting Up GitHub Copilot SDK

### 1. Install the Copilot CLI
Follow the official installation guide: https://docs.github.com/en/copilot/how-tos/set-up/install-copilot-cli

Verify the CLI is working:
```bash
copilot --version
```

### 2. Authenticate with GitHub
Run the following command and follow the prompts to sign in with your GitHub account:
```bash
copilot auth login
```

This will open a browser window for authentication. After successful login, the CLI stores your credentials locally.

### 3. Verify Authentication
```bash
copilot auth status
```

You should see your GitHub username and confirmation that you're authenticated.

### 4. (Optional) Set a Custom Model
By default the SDK uses `gpt-5`. To use a different model, set the `COPILOT_MODEL` environment variable in your `.env`:
```
COPILOT_MODEL="claude-sonnet-4.5"
```

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
| POST   | `/copilot/prompt`  | Send a prompt to Copilot and get a response |

### Copilot Endpoint Usage
```bash
curl -X POST http://127.0.0.1:5000/copilot/prompt \
  -H "Content-Type: application/json" \
  -d '{"prompt": "What is 2 + 2?"}'
```

Response:
```json
{
  "response": "4"
}
```

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
- Copilot CLI not found: ensure `copilot` is in your PATH and run `copilot --version` to verify.
- Copilot authentication errors: run `copilot auth login` to re-authenticate.
- Copilot SDK not installed: the SDK is pulled from GitHub—ensure `git` is available and run `pip install -r requirements.txt` again.

## Next Steps
- Add authentication (JWT/Auth0/Supabase Auth) before exposing the endpoints publicly.
- Create additional CRUD routes per table or abstract logic into service modules for larger projects.
