-- ============================================================
-- CraveBalance Database Schema
-- Run this in Supabase SQL Editor
-- ============================================================

-- 1. Profiles table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS profiles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT,
    email TEXT,
    age INTEGER,
    height REAL,          -- in cm, optional
    weight REAL,          -- in kg, optional
    total_points INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (user_id, name, email)
    VALUES (
        NEW.id,
        NEW.raw_user_meta_data ->> 'full_name',
        NEW.email
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- 2. Sessions table
CREATE TABLE IF NOT EXISTS sessions (
    session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(user_id) ON DELETE CASCADE,
    crave_item TEXT NOT NULL,
    calories INTEGER,
    location_options JSONB,
    session_type TEXT CHECK (session_type IN ('solo_challenge', 'invite_friend', 'challenge_random', 'skip')),
    rating INTEGER CHECK (rating >= 1 AND rating <= 10),
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_sessions_user_id ON sessions(user_id);

-- 3. Challenges table
CREATE TABLE IF NOT EXISTS challenges (
    challenge_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(session_id) ON DELETE CASCADE,
    challenge TEXT NOT NULL,
    time_limit INTEGER NOT NULL,           -- in minutes
    expiry_time TIMESTAMPTZ DEFAULT (now() + INTERVAL '24 hours'),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'completed', 'expired')),
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_challenges_session_id ON challenges(session_id);

-- 4. Ranks table (pre-seeded)
CREATE TABLE IF NOT EXISTS ranks (
    rank_id SERIAL PRIMARY KEY,
    rank_type TEXT NOT NULL UNIQUE,
    min_points INTEGER NOT NULL,
    max_points INTEGER NOT NULL
);

INSERT INTO ranks (rank_type, min_points, max_points) VALUES
    ('Beginner',  0,    99),
    ('Bronze',    100,  499),
    ('Silver',    500,  999),
    ('Gold',      1000, 2499),
    ('Platinum',  2500, 4999),
    ('Diamond',   5000, 999999)
ON CONFLICT (rank_type) DO NOTHING;

-- 5. User Preferences table (normalized context)
CREATE TABLE IF NOT EXISTS user_preferences (
    preference_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(user_id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    item TEXT NOT NULL,
    order_count INTEGER DEFAULT 1,
    last_ordered TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, category, item)
);

CREATE INDEX idx_preferences_user_category ON user_preferences(user_id, category);

-- ============================================================
-- Row Level Security (RLS) Policies
-- ============================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE ranks ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Profiles: users can read/update their own profile
CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = user_id);

-- Sessions: users can CRUD their own sessions
CREATE POLICY "Users can view own sessions"
    ON sessions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sessions"
    ON sessions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own sessions"
    ON sessions FOR UPDATE
    USING (auth.uid() = user_id);

-- Challenges: users can access challenges for their sessions
CREATE POLICY "Users can view own challenges"
    ON challenges FOR SELECT
    USING (
        session_id IN (SELECT session_id FROM sessions WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can insert own challenges"
    ON challenges FOR INSERT
    WITH CHECK (
        session_id IN (SELECT session_id FROM sessions WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can update own challenges"
    ON challenges FOR UPDATE
    USING (
        session_id IN (SELECT session_id FROM sessions WHERE user_id = auth.uid())
    );

-- Ranks: everyone can read ranks
CREATE POLICY "Anyone can view ranks"
    ON ranks FOR SELECT
    USING (true);

-- User Preferences: users can CRUD their own preferences
CREATE POLICY "Users can view own preferences"
    ON user_preferences FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own preferences"
    ON user_preferences FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own preferences"
    ON user_preferences FOR UPDATE
    USING (auth.uid() = user_id);
