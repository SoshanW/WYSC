from enum import Enum


class SessionType(str, Enum):
    SOLO_CHALLENGE = "solo_challenge"
    INVITE_FRIEND = "invite_friend"
    CHALLENGE_RANDOM = "challenge_random"
    HEALTHY_ROUTE = "healthy_route"
    SKIP = "skip"


class ChallengeStatus(str, Enum):
    PENDING = "pending"
    ACTIVE = "active"
    COMPLETED = "completed"
    EXPIRED = "expired"


class InvitationStatus(str, Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    DECLINED = "declined"
    EXPIRED = "expired"


class MatchStatus(str, Enum):
    ACTIVE = "active"
    COMPLETED = "completed"


class QueueStatus(str, Enum):
    WAITING = "waiting"
    MATCHED = "matched"
    CANCELLED = "cancelled"
    EXPIRED = "expired"
