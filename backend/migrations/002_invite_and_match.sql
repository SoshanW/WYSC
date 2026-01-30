-- ============================================================
-- Invite & Match Tables + RLS Policies
-- Run this in Supabase SQL Editor after 001_create_tables.sql
-- ============================================================

-- 1. Invitations table
CREATE TABLE IF NOT EXISTS invitations (
    invitation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(session_id) ON DELETE CASCADE,
    inviter_user_id UUID NOT NULL REFERENCES profiles(user_id),
    invitee_user_id UUID REFERENCES profiles(user_id),
    invite_token TEXT NOT NULL UNIQUE,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending','accepted','declined','expired')),
    invitee_session_id UUID REFERENCES sessions(session_id),
    challenge_description TEXT,
    challenge_time_limit INTEGER,
    expiry_time TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_invitations_token ON invitations(invite_token);
CREATE INDEX idx_invitations_inviter ON invitations(inviter_user_id);

-- 2. Matchmaking queue table
CREATE TABLE IF NOT EXISTS matchmaking_queue (
    queue_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(user_id),
    session_id UUID NOT NULL REFERENCES sessions(session_id),
    calories INTEGER NOT NULL,
    status TEXT DEFAULT 'waiting' CHECK (status IN ('waiting','matched','cancelled','expired')),
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_queue_status ON matchmaking_queue(status);
CREATE INDEX idx_queue_user ON matchmaking_queue(user_id);

-- 3. Matches table
CREATE TABLE IF NOT EXISTS matches (
    match_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user1_id UUID NOT NULL REFERENCES profiles(user_id),
    user2_id UUID NOT NULL REFERENCES profiles(user_id),
    session_id_1 UUID NOT NULL REFERENCES sessions(session_id),
    session_id_2 UUID NOT NULL REFERENCES sessions(session_id),
    challenge_description TEXT NOT NULL,
    challenge_time_limit INTEGER NOT NULL,
    status TEXT DEFAULT 'active' CHECK (status IN ('active','completed')),
    winner_user_id UUID REFERENCES profiles(user_id),
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_matches_users ON matches(user1_id, user2_id);

-- ============================================================
-- Row Level Security (RLS) Policies
-- ============================================================

ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE matchmaking_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;

-- Invitations: users can view invitations where they are inviter OR invitee
CREATE POLICY "Users can view own invitations"
    ON invitations FOR SELECT
    USING (auth.uid() = inviter_user_id OR auth.uid() = invitee_user_id);

-- Invitations: anyone can view by token (for public invite link)
CREATE POLICY "Anyone can view invitation by token"
    ON invitations FOR SELECT
    USING (true);

CREATE POLICY "Users can insert own invitations"
    ON invitations FOR INSERT
    WITH CHECK (auth.uid() = inviter_user_id);

CREATE POLICY "Users can update own invitations"
    ON invitations FOR UPDATE
    USING (auth.uid() = inviter_user_id OR auth.uid() = invitee_user_id);

-- Matchmaking queue: users can CRUD their own queue entries
CREATE POLICY "Users can view own queue entries"
    ON matchmaking_queue FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own queue entries"
    ON matchmaking_queue FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own queue entries"
    ON matchmaking_queue FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own queue entries"
    ON matchmaking_queue FOR DELETE
    USING (auth.uid() = user_id);

-- Matches: users can view matches where they are user1 or user2
CREATE POLICY "Users can view own matches"
    ON matches FOR SELECT
    USING (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Users can insert matches"
    ON matches FOR INSERT
    WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Users can update own matches"
    ON matches FOR UPDATE
    USING (auth.uid() = user1_id OR auth.uid() = user2_id);
