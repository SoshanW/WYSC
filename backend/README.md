# CraveBalance Backend API

Backend API for **CraveBalance** — a gamified craving management app that helps users make healthier choices by pairing cravings with physical challenges, earning points, and climbing ranks.

## Tech Stack

- **Python 3.10+** / **Flask 3.x**
- **Supabase** — Auth, PostgreSQL database, Row Level Security
- **OpenAI API** (`gpt-4o-mini`) — craving option generation, calorie estimation, challenge creation
- **Google Places API** — nearby store/restaurant lookup
- **Swagger/Flasgger** — interactive API documentation

## Project Structure

```
backend/
├── app.py                        # Flask app entry point, blueprint registration
├── config.py                     # Environment variables, Supabase client
├── requirements.txt
├── .env / .env.example
├── routes/
│   ├── auth.py                   # Signup, login, logout, me
│   ├── session.py                # Craving submission, option selection, session type
│   ├── challenge.py              # Challenge lifecycle (select, start, complete)
│   └── user.py                   # Profile, history
├── services/
│   ├── llm_service.py            # OpenAI wrapper (options, calories, challenges)
│   └── places_service.py         # Google Places nearby search
├── middleware/
│   └── auth_middleware.py        # @require_auth decorator
├── models/
│   └── enums.py                  # SessionType, ChallengeStatus enums
├── migrations/
│   └── 001_create_tables.sql     # Full database schema for Supabase
└── rag/
    └── rag_engine.py             # RAG engine (not used in current flow)
```

## Prerequisites

1. Python 3.10+
2. A [Supabase](https://supabase.com) project
3. An [OpenAI API key](https://platform.openai.com/api-keys)
4. A [Google Places API key](https://developers.google.com/maps/documentation/places/web-service/get-api-key) (optional — app works without it using generic options)

## Setup

### 1. Install dependencies

```bash
cd backend
python -m venv venv
source venv/Scripts/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Configure environment variables

Copy `.env.example` to `.env` and fill in your keys:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_TABLE=profiles
OPENAI_API_KEY=sk-your-openai-key
GOOGLE_PLACES_API_KEY=your-google-places-key
```

### 3. Run database migration

Open your **Supabase Dashboard > SQL Editor**, paste the contents of `migrations/001_create_tables.sql`, and run it. This creates:

| Table | Purpose |
|-------|---------|
| `profiles` | User data (name, age, height, weight, total_points) |
| `sessions` | Craving sessions with calories, type, rating |
| `challenges` | Physical challenges with status, time limit, expiry |
| `ranks` | Pre-seeded rank tiers (Beginner through Diamond) |
| `user_preferences` | Per-user craving history for personalization |

It also sets up:
- A trigger that auto-creates a profile row on signup
- Row Level Security policies so users can only access their own data

### 4. Start the server

```bash
python app.py
```

The API runs at `http://localhost:5000`. Swagger docs are at `http://localhost:5000/apidocs/`.

## API Endpoints

### Auth

| Method | Route | Description |
|--------|-------|-------------|
| POST | `/auth/signup` | Create account (email, password, name) |
| POST | `/auth/login` | Sign in, get access token |
| POST | `/auth/logout` | Sign out (requires token) |
| GET | `/auth/me` | Get current user info |

### Session Flow

| Method | Route | Description |
|--------|-------|-------------|
| POST | `/session/crave` | Submit a craving + location, get specific options |
| POST | `/session/select` | Pick an option, get calorie estimate |
| POST | `/session/choose-type` | Choose session type, get challenges (if solo) |

### Challenge Flow

| Method | Route | Description |
|--------|-------|-------------|
| POST | `/challenge/select` | Pick a challenge, creates it with 24h expiry |
| POST | `/challenge/start` | Start a pending challenge |
| POST | `/challenge/complete` | Report completion %, get rating + points + rank |

### User

| Method | Route | Description |
|--------|-------|-------------|
| GET | `/user/profile` | Get profile with current rank |
| PUT | `/user/profile` | Update age, height, weight |
| GET | `/user/history` | Get past sessions with challenges |

### General

| Method | Route | Description |
|--------|-------|-------------|
| GET | `/` | API welcome message |
| GET | `/health` | Health check |
| GET | `/supabase/health` | Supabase connection check |

## User Flow

```
1. Sign up / Log in
         |
2. Submit a craving (e.g. "crepe") + location
         |
3. App finds nearby stores (Google Places)
   + LLM generates specific options
   + Checks user history for personalization
         |
4. User picks an option (e.g. "Chocolate crepe from La Creperie")
         |
5. LLM estimates calories (~350 kcal)
         |
6. User chooses session type:
   - Solo Challenge  --> generates 3 physical challenges
   - Invite Friend   --> (coming soon)
   - Challenge Random --> (coming soon)
   - Skip            --> no points earned
         |
7. User picks and starts a challenge
         |
8. User reports completion (0-100%)
         |
9. System calculates rating + points:
   - Rating > 3/10: points = (rating x calories) / 10
   - Rating <= 3/10: points = -(calories / 10)
         |
10. Points update --> Rank assigned
```

## Rank System

| Rank | Points Required |
|------|----------------|
| Beginner | 0 - 99 |
| Bronze | 100 - 499 |
| Silver | 500 - 999 |
| Gold | 1,000 - 2,499 |
| Platinum | 2,500 - 4,999 |
| Diamond | 5,000+ |

## Personalization

The app learns from user behavior. The `user_preferences` table tracks what each user orders and how often. Once a user has **5+ orders** in a craving category (e.g. "crepe"), future suggestions for that category are personalized based on their history.

## Testing the Full Flow

```bash
# 1. Sign up
curl -X POST http://localhost:5000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email": "test@test.com", "password": "pass123", "name": "John"}'
# Copy the access_token from the response

# 2. Set profile
curl -X PUT http://localhost:5000/user/profile \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"age": 25, "weight": 70}'

# 3. Submit craving
curl -X POST http://localhost:5000/session/crave \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"crave_item": "crepe", "latitude": 6.9271, "longitude": 79.8612}'

# 4. Select option (use session_id from step 3)
curl -X POST http://localhost:5000/session/select \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"session_id": "SESSION_ID", "selected_option": "Chocolate crepe"}'

# 5. Choose solo challenge
curl -X POST http://localhost:5000/session/choose-type \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"session_id": "SESSION_ID", "session_type": "solo_challenge"}'

# 6. Select a challenge (use one from step 5 response)
curl -X POST http://localhost:5000/challenge/select \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"session_id": "SESSION_ID", "challenge_description": "20-min brisk walk", "time_limit": 20}'

# 7. Start it
curl -X POST http://localhost:5000/challenge/start \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"challenge_id": "CHALLENGE_ID"}'

# 8. Complete it
curl -X POST http://localhost:5000/challenge/complete \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"challenge_id": "CHALLENGE_ID", "completion_percentage": 75}'

# 9. Check profile + rank
curl -X GET http://localhost:5000/user/profile \
  -H "Authorization: Bearer TOKEN"
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `Missing or invalid Authorization header` | Include `Authorization: Bearer <token>` header |
| `OPENAI_API_KEY is not configured` | Add `OPENAI_API_KEY` to `.env` |
| Places returning empty results | Check `GOOGLE_PLACES_API_KEY` in `.env`, or test without it (generic options) |
| `Session not found` | Ensure the session belongs to the authenticated user |
| SQL migration errors | Run the migration in Supabase SQL Editor, not locally |
| `profiles` table already exists | The migration uses `IF NOT EXISTS` — safe to re-run |
