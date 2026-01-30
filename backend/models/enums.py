from enum import Enum


class SessionType(str, Enum):
    SOLO_CHALLENGE = "solo_challenge"
    INVITE_FRIEND = "invite_friend"
    CHALLENGE_RANDOM = "challenge_random"
    SKIP = "skip"


class ChallengeStatus(str, Enum):
    PENDING = "pending"
    ACTIVE = "active"
    COMPLETED = "completed"
    EXPIRED = "expired"
