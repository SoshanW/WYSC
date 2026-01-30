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
│   ├── invite.py                 # Invite a friend (create, view, respond, status)
│   ├── match.py                  # Challenge a random player (queue, status, cancel)
│   └── user.py                   # Profile, history
├── services/
│   ├── llm_service.py            # OpenAI wrapper (options, calories, challenges)
│   └── places_service.py         # Google Places nearby search
├── middleware/
│   └── auth_middleware.py        # @require_auth decorator
├── models/
│   └── enums.py                  # SessionType, ChallengeStatus, InvitationStatus, MatchStatus, QueueStatus
├── migrations/
│   ├── 001_create_tables.sql     # Core database schema
│   └── 002_invite_and_match.sql  # Invitations, matchmaking queue, matches tables
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

Open your **Supabase Dashboard > SQL Editor**, paste and run each migration file in order:

**Migration 1** — `migrations/001_create_tables.sql`:

| Table | Purpose |
|-------|---------|
| `profiles` | User data (name, age, height, weight, total_points) |
| `sessions` | Craving sessions with calories, type, rating |
| `challenges` | Physical challenges with status, time limit, expiry |
| `ranks` | Pre-seeded rank tiers (Beginner through Diamond) |
| `user_preferences` | Per-user craving history for personalization |

**Migration 2** — `migrations/002_invite_and_match.sql`:

| Table | Purpose |
|-------|---------|
| `invitations` | Friend invite tokens, status tracking, expiry |
| `matchmaking_queue` | Users waiting to be matched by calorie range |
| `matches` | Paired random matches with shared challenge, winner tracking |

Both migrations set up:
- A trigger that auto-creates a profile row on signup (migration 1)
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
| POST | `/challenge/complete` | Report completion %, get rating + points + rank (1.5x bonus for match winners) |

### Invite a Friend

| Method | Route | Auth | Description |
|--------|-------|------|-------------|
| POST | `/invite/create` | Yes | Create an invite with a chosen challenge (5-min expiry token) |
| GET | `/invite/<token>` | No | View invite details (public link for the friend) |
| POST | `/invite/respond` | Yes | Accept or decline an invite |
| GET | `/invite/status/<invitation_id>` | Yes | Poll invite status (pending/accepted/declined/expired) |

### Challenge a Random Player

| Method | Route | Auth | Description |
|--------|-------|------|-------------|
| POST | `/match/queue` | Yes | Join matchmaking queue; instant match if opponent found within +/-50 calories |
| GET | `/match/status/<queue_id>` | Yes | Poll queue status (waiting/matched/expired) |
| POST | `/match/cancel` | Yes | Cancel a waiting queue entry |

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

## User Flows

### Common Steps (all session types)

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
   - Solo Challenge   --> Path A
   - Invite Friend    --> Path B
   - Challenge Random --> Path C
   - Skip             --> no points earned
```

### Path A: Solo Challenge

```
6a. choose-type (session_type=solo_challenge) --> returns 3 challenges
         |
7a. Pick a challenge --> POST /challenge/select
         |
8a. Start it --> POST /challenge/start
         |
9a. Complete it (0-100%) --> POST /challenge/complete
         |
10a. Points awarded, rank updated
```

### Path B: Invite a Friend

```
6b. choose-type (session_type=invite_friend) --> returns 3 challenges
         |
7b. Inviter picks a challenge + creates invite --> POST /invite/create
     Returns: invite_token, invite_link, challenge_id
         |
8b. Share the invite link with a friend
     Friend opens: GET /invite/<token> (no auth, public)
         |
9b. Friend accepts: POST /invite/respond (action=accept)
     System creates a session + challenge for the friend (same challenge)
         |
10b. Inviter polls: GET /invite/status/<invitation_id> to see "accepted"
         |
11b. Both users independently:
     POST /challenge/start --> POST /challenge/complete
         |
12b. Points awarded to each user based on their own completion
```

### Path C: Challenge a Random Player

```
6c. choose-type (session_type=challenge_random) --> returns queue instructions
         |
7c. User joins queue: POST /match/queue
         |
    ┌─── If opponent found (calories within +/-50) ───┐
    │  Instant match! Returns: match_id,               │
    │  opponent_name, challenge, challenge_id           │
    └──────────────────────────────────────────────────┘
    ┌─── If no opponent yet ───────────────────────────┐
    │  Returns: queue_id, "Waiting for opponent..."     │
    │  Poll: GET /match/status/<queue_id>               │
    │  Cancel: POST /match/cancel                       │
    │  Auto-expires after 10 minutes                    │
    └──────────────────────────────────────────────────┘
         |
8c. Once matched, both users independently:
    POST /challenge/start --> POST /challenge/complete
         |
9c. Points awarded with match bonus:
    - First to complete with higher rating: 1.5x points
    - Other player: normal points
    - Match marked completed + winner set when both finish
```

## Points Formula

| Scenario | Formula |
|----------|---------|
| Rating > 3/10 (solo or invite) | `floor(rating * calories / 10)` |
| Rating <= 3/10 | `-floor(calories / 10)` |
| Random match winner (1.5x bonus) | `floor(base_points * 1.5)` |

The **match winner** is the first player to complete with a higher completion rating. If both have completed, the one with the higher rating wins the bonus. Total points never go below 0.

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

### Setup (all flows start here)

```bash
# 1. Sign up
curl -X POST http://localhost:5000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email": "test@test.com", "password": "pass123", "name": "John"}'
# Save the access_token as TOKEN_A

# 2. Set profile
curl -X PUT http://localhost:5000/user/profile \
  -H "Authorization: Bearer TOKEN_A" \
  -H "Content-Type: application/json" \
  -d '{"age": 25, "weight": 70}'

# 3. Submit craving
curl -X POST http://localhost:5000/session/crave \
  -H "Authorization: Bearer TOKEN_A" \
  -H "Content-Type: application/json" \
  -d '{"crave_item": "crepe", "latitude": 6.9271, "longitude": 79.8612}'
# Save session_id from response

# 4. Select option
curl -X POST http://localhost:5000/session/select \
  -H "Authorization: Bearer TOKEN_A" \
  -H "Content-Type: application/json" \
  -d '{"session_id": "SESSION_ID", "selected_option": "Chocolate crepe"}'
```

### Test A: Solo Challenge Flow

```bash
# 5. Choose solo challenge
curl -X POST http://localhost:5000/session/choose-type \
  -H "Authorization: Bearer TOKEN_A" \
  -H "Content-Type: application/json" \
  -d '{"session_id": "SESSION_ID", "session_type": "solo_challenge"}'
# Returns 3 challenges — pick one

# 6. Select a challenge
curl -X POST http://localhost:5000/challenge/select \
  -H "Authorization: Bearer TOKEN_A" \
  -H "Content-Type: application/json" \
  -d '{"session_id": "SESSION_ID", "challenge_description": "20-min brisk walk", "time_limit": 20}'
# Save challenge_id

# 7. Start it
curl -X POST http://localhost:5000/challenge/start \
  -H "Authorization: Bearer TOKEN_A" \
  -H "Content-Type: application/json" \
  -d '{"challenge_id": "CHALLENGE_ID"}'

# 8. Complete it
curl -X POST http://localhost:5000/challenge/complete \
  -H "Authorization: Bearer TOKEN_A" \
  -H "Content-Type: application/json" \
  -d '{"challenge_id": "CHALLENGE_ID", "completion_percentage": 75}'

# 9. Check profile + rank
curl -X GET http://localhost:5000/user/profile \
  -H "Authorization: Bearer TOKEN_A"
```

### Test B: Invite a Friend Flow

Requires **two user accounts**. Complete the setup steps (1-4) for User A first.

```bash
# --- USER A (inviter) ---

# 5. Choose invite_friend (returns 3 challenges to pick from)
curl -X POST http://localhost:5000/session/choose-type \
  -H "Authorization: Bearer TOKEN_A" \
  -H "Content-Type: application/json" \
  -d '{"session_id": "SESSION_ID_A", "session_type": "invite_friend"}'
# Pick one challenge from the response

# 6. Create the invite
curl -X POST http://localhost:5000/invite/create \
  -H "Authorization: Bearer TOKEN_A" \
  -H "Content-Type: application/json" \
  -d '{"session_id": "SESSION_ID_A", "challenge_description": "20-min brisk walk", "time_limit": 20}'
# Save: invite_token, invitation_id, challenge_id (inviter's challenge)
# Note: the invite expires in 5 minutes!

# 7. (Optional) View the invite link — no auth needed
curl -X GET http://localhost:5000/invite/INVITE_TOKEN

# --- USER B (invitee) ---
# Sign up a second user first, save token as TOKEN_B

# 8. Accept the invite
curl -X POST http://localhost:5000/invite/respond \
  -H "Authorization: Bearer TOKEN_B" \
  -H "Content-Type: application/json" \
  -d '{"invite_token": "INVITE_TOKEN", "action": "accept"}'
# Save: session_id (invitee's session), challenge_id (invitee's challenge)

# --- USER A polls for acceptance ---

# 9. Check invite status
curl -X GET http://localhost:5000/invite/status/INVITATION_ID \
  -H "Authorization: Bearer TOKEN_A"
# Should show: status=accepted, invitee_name

# --- BOTH USERS complete their challenges independently ---

# 10a. User A starts + completes
curl -X POST http://localhost:5000/challenge/start \
  -H "Authorization: Bearer TOKEN_A" \
  -H "Content-Type: application/json" \
  -d '{"challenge_id": "CHALLENGE_ID_A"}'

curl -X POST http://localhost:5000/challenge/complete \
  -H "Authorization: Bearer TOKEN_A" \
  -H "Content-Type: application/json" \
  -d '{"challenge_id": "CHALLENGE_ID_A", "completion_percentage": 80}'

# 10b. User B starts + completes
curl -X POST http://localhost:5000/challenge/start \
  -H "Authorization: Bearer TOKEN_B" \
  -H "Content-Type: application/json" \
  -d '{"challenge_id": "CHALLENGE_ID_B"}'

curl -X POST http://localhost:5000/challenge/complete \
  -H "Authorization: Bearer TOKEN_B" \
  -H "Content-Type: application/json" \
  -d '{"challenge_id": "CHALLENGE_ID_B", "completion_percentage": 60}'
```

**Edge cases to test:**
- Declining: `{"invite_token": "TOKEN", "action": "decline"}`
- Self-invite: try accepting your own invite (should return error)
- Expired invite: wait 5 minutes, then try to accept (should return error)
- Double accept: accept the same invite twice (should return error)

### Test C: Challenge a Random Player Flow

Requires **two user accounts** with sessions that have similar calorie values (within +/-50).
Complete the setup steps (1-4) for both users.

```bash
# --- USER A enters the queue ---

# 5a. Choose challenge_random
curl -X POST http://localhost:5000/session/choose-type \
  -H "Authorization: Bearer TOKEN_A" \
  -H "Content-Type: application/json" \
  -d '{"session_id": "SESSION_ID_A", "session_type": "challenge_random"}'

# 6a. Join the matchmaking queue
curl -X POST http://localhost:5000/match/queue \
  -H "Authorization: Bearer TOKEN_A" \
  -H "Content-Type: application/json" \
  -d '{"session_id": "SESSION_ID_A"}'
# If no opponent yet: save queue_id, matched=false
# If opponent already waiting: matched=true, save match_id + challenge_id

# 7a. (If waiting) Poll for a match
curl -X GET http://localhost:5000/match/status/QUEUE_ID_A \
  -H "Authorization: Bearer TOKEN_A"

# --- USER B enters the queue (triggers the match if calories are close) ---

# 5b. Choose challenge_random
curl -X POST http://localhost:5000/session/choose-type \
  -H "Authorization: Bearer TOKEN_B" \
  -H "Content-Type: application/json" \
  -d '{"session_id": "SESSION_ID_B", "session_type": "challenge_random"}'

# 6b. Join the queue — should instantly match with User A
curl -X POST http://localhost:5000/match/queue \
  -H "Authorization: Bearer TOKEN_B" \
  -H "Content-Type: application/json" \
  -d '{"session_id": "SESSION_ID_B"}'
# Should return: matched=true, match_id, opponent_name, challenge, challenge_id

# 7b. User A polls again and should now see "matched"
curl -X GET http://localhost:5000/match/status/QUEUE_ID_A \
  -H "Authorization: Bearer TOKEN_A"
# Returns: status=matched, match_id, opponent_name, challenge_id

# --- BOTH USERS complete their challenges ---

# 8a. User A starts + completes (first to complete gets 1.5x if higher rating)
curl -X POST http://localhost:5000/challenge/start \
  -H "Authorization: Bearer TOKEN_A" \
  -H "Content-Type: application/json" \
  -d '{"challenge_id": "CHALLENGE_ID_A"}'

curl -X POST http://localhost:5000/challenge/complete \
  -H "Authorization: Bearer TOKEN_A" \
  -H "Content-Type: application/json" \
  -d '{"challenge_id": "CHALLENGE_ID_A", "completion_percentage": 90}'
# Response includes: match_id, winner_bonus=true (if first + positive points)

# 8b. User B starts + completes
curl -X POST http://localhost:5000/challenge/start \
  -H "Authorization: Bearer TOKEN_B" \
  -H "Content-Type: application/json" \
  -d '{"challenge_id": "CHALLENGE_ID_B"}'

curl -X POST http://localhost:5000/challenge/complete \
  -H "Authorization: Bearer TOKEN_B" \
  -H "Content-Type: application/json" \
  -d '{"challenge_id": "CHALLENGE_ID_B", "completion_percentage": 50}'
# Response includes: match_id, winner_bonus=false
# Match is now marked completed with winner_user_id set
```

**Edge cases to test:**
- Cancel queue: `POST /match/cancel` with `{"queue_id": "QUEUE_ID"}` (only works while waiting)
- Already in queue: try joining queue twice (should return error)
- Queue timeout: wait 10 minutes without a match, then poll status (should show expired)
- Calorie mismatch: two users with calories 200 apart won't match (stays waiting)

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `Missing or invalid Authorization header` | Include `Authorization: Bearer <token>` header |
| `OPENAI_API_KEY is not configured` | Add `OPENAI_API_KEY` to `.env` |
| Places returning empty results | Check `GOOGLE_PLACES_API_KEY` in `.env`, or test without it (generic options) |
| `Session not found` | Ensure the session belongs to the authenticated user |
| SQL migration errors | Run the migration in Supabase SQL Editor, not locally |
| `profiles` table already exists | The migration uses `IF NOT EXISTS` — safe to re-run |
| `Invitation has expired` | Invites expire after 5 minutes — create a new one |
| `You cannot accept your own invitation` | Log in as a different user to accept |
| `You are already in the matchmaking queue` | Cancel your existing entry first via `POST /match/cancel` |
| No match found | The other user's calories must be within +/-50 of yours |
| `invitations` table missing | Run `migrations/002_invite_and_match.sql` in Supabase SQL Editor |
