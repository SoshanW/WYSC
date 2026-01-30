# CraveBalance — Frontend Integration Guide

Base URL: `http://localhost:5000`

Swagger UI: `http://localhost:5000/apidocs/`

---

## Authentication

All endpoints except `/auth/signup` and `/auth/login` require an `Authorization` header:

```
Authorization: Bearer <access_token>
```

The `access_token` is returned from signup/login responses.

---

## User Flow

```
Signup/Login → Update Profile → Submit Craving → Select Option → Choose Session Type
                                                                        |
                                                          Solo Challenge selected
                                                                        |
                                                          Pick Challenge → Start → Complete
                                                                        |
                                                              Points + Rank awarded
```

---

## API Reference

### 1. Sign Up

```
POST /auth/signup
```

**Request:**
```json
{
  "email": "user@example.com",
  "password": "pass123",
  "name": "John Doe"
}
```

**Response (201):**
```json
{
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "full_name": "John Doe"
    },
    "session": {
      "access_token": "eyJhbGci...",
      "refresh_token": "abc123..."
    }
  }
}
```

Store `access_token` — use it in all subsequent requests.

---

### 2. Login

```
POST /auth/login
```

**Request:**
```json
{
  "email": "user@example.com",
  "password": "pass123"
}
```

**Response (200):** Same structure as signup.

---

### 3. Get Profile

```
GET /user/profile
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "data": {
    "user_id": "uuid",
    "name": "John Doe",
    "email": "user@example.com",
    "age": 25,
    "height": 175.5,
    "weight": 70.0,
    "total_points": 245,
    "rank": "Bronze"
  }
}
```

---

### 4. Update Profile

```
PUT /user/profile
Authorization: Bearer <token>
```

**Request (all fields optional):**
```json
{
  "name": "John Doe",
  "age": 25,
  "height": 175.5,
  "weight": 70.0
}
```

**Response (200):**
```json
{
  "data": {
    "message": "Profile updated.",
    "updated_fields": ["age", "weight"]
  }
}
```

---

### 5. Submit Craving

This is the main entry point. User types a generic craving and provides their location.

```
POST /session/crave
Authorization: Bearer <token>
```

**Request:**
```json
{
  "crave_item": "crepe",
  "latitude": 6.9271,
  "longitude": 79.8612
}
```

**Frontend note:** Get lat/lng from the device's geolocation API.

**Response (200):**
```json
{
  "data": {
    "session_id": "uuid",
    "options": [
      {
        "option": "Chocolate Crepe",
        "store": "La Creperie",
        "description": "Rich chocolate crepe with whipped cream"
      },
      {
        "option": "Strawberry Crepe",
        "store": "Cafe Bistro",
        "description": "Fresh strawberry crepe with Nutella drizzle"
      }
    ],
    "personalized": false
  }
}
```

**Frontend should:** Display the options as selectable cards/list items. The `personalized` flag indicates whether suggestions were tailored to the user's history (show a badge or note if true).

---

### 6. Select an Option

User picks one of the options from step 5.

```
POST /session/select
Authorization: Bearer <token>
```

**Request:**
```json
{
  "session_id": "uuid-from-step-5",
  "selected_option": "Chocolate Crepe from La Creperie"
}
```

**Response (200):**
```json
{
  "data": {
    "session_id": "uuid",
    "selected_item": "Chocolate Crepe from La Creperie",
    "estimated_calories": 350,
    "session_types": [
      "solo_challenge",
      "invite_friend",
      "challenge_random",
      "skip"
    ]
  }
}
```

**Frontend should:** Show the calorie estimate prominently, then present the 4 session type buttons:
- Solo Challenge (active)
- Invite a Friend (show "Coming Soon")
- Challenge Random Player (show "Coming Soon")
- Skip (active — no challenge, no points)

---

### 7. Choose Session Type

```
POST /session/choose-type
Authorization: Bearer <token>
```

**Request:**
```json
{
  "session_id": "uuid",
  "session_type": "solo_challenge"
}
```

Valid values: `solo_challenge`, `invite_friend`, `challenge_random`, `skip`

**Response for `solo_challenge` (200):**
```json
{
  "data": {
    "session_id": "uuid",
    "session_type": "solo_challenge",
    "challenges": [
      {
        "description": "Take a 25-minute brisk walk around your neighborhood",
        "time_limit": 25
      },
      {
        "description": "Do a 15-minute jog at moderate pace",
        "time_limit": 15
      },
      {
        "description": "Complete 30 squats, 20 push-ups, and 20 lunges",
        "time_limit": 12
      }
    ]
  }
}
```

**Response for `skip` (200):**
```json
{
  "data": {
    "session_id": "uuid",
    "session_type": "skip",
    "message": "Session skipped. No points earned."
  }
}
```

**Frontend should:** Display the 3 challenges as cards showing description and time limit (in minutes). Let the user tap one to select it.

---

### 8. Select a Challenge

User picks one of the 3 challenges.

```
POST /challenge/select
Authorization: Bearer <token>
```

**Request:**
```json
{
  "session_id": "uuid",
  "challenge_description": "Take a 25-minute brisk walk around your neighborhood",
  "time_limit": 25
}
```

**Response (201):**
```json
{
  "data": {
    "challenge_id": "uuid",
    "challenge": "Take a 25-minute brisk walk around your neighborhood",
    "time_limit": 25,
    "expiry_time": "2026-02-01T19:30:00+00:00",
    "status": "pending"
  }
}
```

**Frontend should:** Show a confirmation screen with:
- The challenge description
- Time limit
- Expiry countdown (24 hours from creation)
- A "Start Challenge" button
- A note: "You can start this challenge anytime before it expires"

---

### 9. Start the Challenge

```
POST /challenge/start
Authorization: Bearer <token>
```

**Request:**
```json
{
  "challenge_id": "uuid-from-step-8"
}
```

**Response (200):**
```json
{
  "data": {
    "challenge_id": "uuid",
    "status": "active",
    "started_at": "2026-01-31T20:00:00+00:00"
  }
}
```

**Frontend should:** Show an active challenge screen — optionally with a timer counting the `time_limit` minutes. When done, show a completion slider or input.

---

### 10. Complete the Challenge

User reports how much of the challenge they completed.

```
POST /challenge/complete
Authorization: Bearer <token>
```

**Request:**
```json
{
  "challenge_id": "uuid",
  "completion_percentage": 75
}
```

`completion_percentage` is 0-100. This gets converted to a 1-10 rating server-side.

**Response (200):**
```json
{
  "data": {
    "rating": 8,
    "completion_percentage": 75,
    "points_earned": 280,
    "total_points": 525,
    "rank": "Silver"
  }
}
```

**Frontend should:** Show a results/reward screen with:
- Rating (e.g., 8/10 with stars or a gauge)
- Points earned (highlight if positive, show in red if negative)
- New total points
- Current rank with a badge/icon
- Celebrate if rank changed (e.g., "You ranked up to Silver!")

---

### 11. Session History

```
GET /user/history
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "data": {
    "sessions": [
      {
        "session_id": "uuid",
        "crave_item": "Chocolate Crepe from La Creperie",
        "calories": 350,
        "session_type": "solo_challenge",
        "rating": 8,
        "created_at": "2026-01-31T19:30:00+00:00",
        "challenges": [
          {
            "challenge_id": "uuid",
            "challenge": "Take a 25-minute brisk walk",
            "time_limit": 25,
            "status": "completed",
            "expiry_time": "2026-02-01T19:30:00+00:00",
            "created_at": "2026-01-31T19:30:00+00:00"
          }
        ]
      }
    ]
  }
}
```

---

## Error Handling

All errors return JSON:

```json
{
  "error": "Description of what went wrong"
}
```

| Status Code | Meaning |
|-------------|---------|
| 400 | Bad request — missing or invalid fields |
| 401 | Unauthorized — missing or expired token |
| 404 | Not found — session/challenge doesn't exist or doesn't belong to user |
| 502 | LLM service error — OpenAI API issue |
| 500 | Server error — unexpected failure |

---

## Rank Tiers

Use these for displaying rank badges/icons:

| Rank | Points | Suggested Color |
|------|--------|-----------------|
| Beginner | 0 – 99 | Grey |
| Bronze | 100 – 499 | #CD7F32 |
| Silver | 500 – 999 | #C0C0C0 |
| Gold | 1,000 – 2,499 | #FFD700 |
| Platinum | 2,500 – 4,999 | #E5E4E2 |
| Diamond | 5,000+ | #B9F2FF |

---

## Suggested Screens

1. **Splash** → existing
2. **Onboarding** → existing
3. **Login / Signup** → existing, wire to `/auth/login` and `/auth/signup`
4. **Profile Setup** → after first login, collect age/weight via `PUT /user/profile`
5. **Home / Craving Input** → text field + location permission, calls `/session/crave`
6. **Options List** → display options from step 5, tap to select
7. **Calorie & Session Type** → show calories, 4 session type buttons
8. **Challenge Picker** → 3 challenge cards from solo_challenge response
9. **Challenge Active** → timer/progress screen after starting
10. **Completion Input** → slider (0-100%) for how much they completed
11. **Results** → rating, points, rank, celebration animation
12. **History** → list of past sessions from `/user/history`
13. **Profile** → show user info, total points, rank from `/user/profile`
