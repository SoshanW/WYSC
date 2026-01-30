-- ============================================================
-- Add healthy_route session type
-- Run this in Supabase SQL Editor after 002_invite_and_match.sql
-- ============================================================

-- Update the sessions CHECK constraint to include healthy_route
ALTER TABLE sessions DROP CONSTRAINT IF EXISTS sessions_session_type_check;
ALTER TABLE sessions ADD CONSTRAINT sessions_session_type_check
    CHECK (session_type IN ('solo_challenge', 'invite_friend', 'challenge_random', 'healthy_route', 'skip'));
