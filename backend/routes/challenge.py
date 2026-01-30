import math
from datetime import datetime, timedelta, timezone

from flask import Blueprint, g, jsonify, request

from config import get_supabase_client
from middleware.auth_middleware import require_auth
from models.enums import ChallengeStatus

challenge_bp = Blueprint("challenge", __name__)

CHALLENGE_EXPIRY_HOURS = 24


@challenge_bp.route("/select", methods=["POST"])
@require_auth
def select_challenge():
    """Pick a challenge from the generated options
    ---
    tags:
      - Challenge
    security:
      - Bearer: []
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          required:
            - session_id
            - challenge_description
            - time_limit
          properties:
            session_id:
              type: string
            challenge_description:
              type: string
              example: "Take a 20-minute brisk walk"
            time_limit:
              type: integer
              example: 20
              description: Duration in minutes
    responses:
      201:
        description: Challenge created
      400:
        description: Missing fields
      404:
        description: Session not found
      500:
        description: Server error
    """
    body = request.get_json(silent=True) or {}
    session_id = body.get("session_id")
    challenge_desc = body.get("challenge_description")
    time_limit = body.get("time_limit")

    if not session_id or not challenge_desc or time_limit is None:
        return jsonify({"error": "session_id, challenge_description and time_limit are required."}), 400

    try:
        supabase = get_supabase_client()

        # Verify session belongs to user
        sess_resp = (
            supabase.table("sessions")
            .select("session_id")
            .eq("session_id", session_id)
            .eq("user_id", g.user_id)
            .execute()
        )
        if not sess_resp.data:
            return jsonify({"error": "Session not found."}), 404

        expiry = (datetime.now(timezone.utc) + timedelta(hours=CHALLENGE_EXPIRY_HOURS)).isoformat()

        challenge_resp = (
            supabase.table("challenges")
            .insert({
                "session_id": session_id,
                "challenge": challenge_desc,
                "time_limit": int(time_limit),
                "expiry_time": expiry,
                "status": ChallengeStatus.PENDING.value,
            })
            .execute()
        )
        challenge = challenge_resp.data[0]

        return jsonify({
            "data": {
                "challenge_id": challenge["challenge_id"],
                "challenge": challenge["challenge"],
                "time_limit": challenge["time_limit"],
                "expiry_time": challenge["expiry_time"],
                "status": challenge["status"],
            }
        }), 201

    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@challenge_bp.route("/start", methods=["POST"])
@require_auth
def start_challenge():
    """Start a pending challenge
    ---
    tags:
      - Challenge
    security:
      - Bearer: []
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          required:
            - challenge_id
          properties:
            challenge_id:
              type: string
    responses:
      200:
        description: Challenge started
      400:
        description: Challenge cannot be started
      404:
        description: Challenge not found
      500:
        description: Server error
    """
    body = request.get_json(silent=True) or {}
    challenge_id = body.get("challenge_id")

    if not challenge_id:
        return jsonify({"error": "challenge_id is required."}), 400

    try:
        supabase = get_supabase_client()

        # Fetch challenge and verify ownership via session
        ch_resp = (
            supabase.table("challenges")
            .select("*, sessions(user_id)")
            .eq("challenge_id", challenge_id)
            .execute()
        )
        if not ch_resp.data:
            return jsonify({"error": "Challenge not found."}), 404

        challenge = ch_resp.data[0]
        if challenge.get("sessions", {}).get("user_id") != g.user_id:
            return jsonify({"error": "Challenge not found."}), 404

        if challenge["status"] != ChallengeStatus.PENDING.value:
            return jsonify({"error": f"Challenge is already {challenge['status']}."}), 400

        # Check expiry
        expiry = datetime.fromisoformat(challenge["expiry_time"])
        if datetime.now(timezone.utc) > expiry:
            supabase.table("challenges").update(
                {"status": ChallengeStatus.EXPIRED.value}
            ).eq("challenge_id", challenge_id).execute()
            return jsonify({"error": "Challenge has expired."}), 400

        supabase.table("challenges").update(
            {"status": ChallengeStatus.ACTIVE.value}
        ).eq("challenge_id", challenge_id).execute()

        return jsonify({
            "data": {
                "challenge_id": challenge_id,
                "status": ChallengeStatus.ACTIVE.value,
                "started_at": datetime.now(timezone.utc).isoformat(),
            }
        }), 200

    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@challenge_bp.route("/complete", methods=["POST"])
@require_auth
def complete_challenge():
    """Report challenge completion and receive rating/points
    ---
    tags:
      - Challenge
    security:
      - Bearer: []
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          required:
            - challenge_id
            - completion_percentage
          properties:
            challenge_id:
              type: string
            completion_percentage:
              type: integer
              minimum: 0
              maximum: 100
              example: 75
    responses:
      200:
        description: Challenge completed, points awarded
      400:
        description: Invalid input or challenge state
      404:
        description: Challenge not found
      500:
        description: Server error
    """
    body = request.get_json(silent=True) or {}
    challenge_id = body.get("challenge_id")
    completion = body.get("completion_percentage")

    if not challenge_id or completion is None:
        return jsonify({"error": "challenge_id and completion_percentage are required."}), 400

    completion = max(0, min(100, int(completion)))

    try:
        supabase = get_supabase_client()

        # Fetch challenge with session data
        ch_resp = (
            supabase.table("challenges")
            .select("*, sessions(session_id, user_id, calories, crave_item)")
            .eq("challenge_id", challenge_id)
            .execute()
        )
        if not ch_resp.data:
            return jsonify({"error": "Challenge not found."}), 404

        challenge = ch_resp.data[0]
        session = challenge.get("sessions", {})

        if session.get("user_id") != g.user_id:
            return jsonify({"error": "Challenge not found."}), 404

        if challenge["status"] != ChallengeStatus.ACTIVE.value:
            return jsonify({"error": f"Challenge is {challenge['status']}, not active."}), 400

        # Derive rating (1-10) from completion percentage
        rating = max(1, min(10, math.ceil(completion / 10)))

        calories = session.get("calories") or 300

        # Calculate base points
        if rating > 3:
            points = math.floor((rating * calories) / 10)
        else:
            points = -math.floor(calories / 10)

        # Check if this challenge belongs to a random match
        is_match = False
        match_info = None
        match_id = None

        if session.get("session_type") == "challenge_random":
            # Look up match by session_id
            match_resp = (
                supabase.table("matches")
                .select("*")
                .or_(
                    f"session_id_1.eq.{session['session_id']},session_id_2.eq.{session['session_id']}"
                )
                .eq("status", "active")
                .execute()
            )
            if match_resp.data:
                is_match = True
                match_info = match_resp.data[0]
                match_id = match_info["match_id"]

        # Update challenge status
        supabase.table("challenges").update(
            {"status": ChallengeStatus.COMPLETED.value}
        ).eq("challenge_id", challenge_id).execute()

        # Update session rating
        supabase.table("sessions").update(
            {"rating": rating}
        ).eq("session_id", session["session_id"]).execute()

        # Apply match winner bonus if applicable
        winner_bonus = False
        if is_match and match_info:
            # Determine opponent session
            if match_info["session_id_1"] == session["session_id"]:
                opponent_session_id = match_info["session_id_2"]
                opponent_user_id = match_info["user2_id"]
            else:
                opponent_session_id = match_info["session_id_1"]
                opponent_user_id = match_info["user1_id"]

            # Check if opponent has completed their challenge
            opp_challenge_resp = (
                supabase.table("challenges")
                .select("status, challenge_id")
                .eq("session_id", opponent_session_id)
                .execute()
            )
            opponent_completed = False
            if opp_challenge_resp.data:
                opponent_completed = opp_challenge_resp.data[0].get("status") == ChallengeStatus.COMPLETED.value

            if not opponent_completed:
                # First to complete — gets 1.5x bonus
                if points > 0:
                    points = math.floor(points * 1.5)
                    winner_bonus = True
            else:
                # Opponent already completed — check opponent's rating
                opp_session_resp = (
                    supabase.table("sessions")
                    .select("rating")
                    .eq("session_id", opponent_session_id)
                    .execute()
                )
                opp_rating = opp_session_resp.data[0].get("rating", 0) if opp_session_resp.data else 0

                if rating > opp_rating and points > 0:
                    # Current user has higher rating — they get the bonus
                    points = math.floor(points * 1.5)
                    winner_bonus = True

            # If both have now completed, mark match as completed and set winner
            if opponent_completed:
                opp_session_resp = (
                    supabase.table("sessions")
                    .select("rating")
                    .eq("session_id", opponent_session_id)
                    .execute()
                )
                opp_rating = opp_session_resp.data[0].get("rating", 0) if opp_session_resp.data else 0

                winner_id = g.user_id if rating >= opp_rating else opponent_user_id
                supabase.table("matches").update({
                    "status": "completed",
                    "winner_user_id": winner_id,
                }).eq("match_id", match_id).execute()

        # Update user total points (floor at 0)
        profile_resp = (
            supabase.table("profiles")
            .select("total_points")
            .eq("user_id", g.user_id)
            .execute()
        )
        current_points = profile_resp.data[0]["total_points"] if profile_resp.data else 0
        new_total = max(0, current_points + points)

        supabase.table("profiles").update(
            {"total_points": new_total}
        ).eq("user_id", g.user_id).execute()

        # Upsert user preference
        crave_item = session.get("crave_item", "")
        category = crave_item.split(" ")[-1].lower() if crave_item else "unknown"
        _upsert_preference(supabase, g.user_id, category, crave_item)

        # Look up rank
        rank_resp = (
            supabase.table("ranks")
            .select("rank_type")
            .lte("min_points", new_total)
            .gte("max_points", new_total)
            .execute()
        )
        rank = rank_resp.data[0]["rank_type"] if rank_resp.data else "Beginner"

        result = {
            "rating": rating,
            "completion_percentage": completion,
            "points_earned": points,
            "total_points": new_total,
            "rank": rank,
        }

        if is_match:
            result["match_id"] = match_id
            result["winner_bonus"] = winner_bonus

        return jsonify({"data": result}), 200

    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


def _upsert_preference(supabase, user_id: str, category: str, item: str):
    """Increment order_count if preference exists, otherwise create it."""
    existing = (
        supabase.table("user_preferences")
        .select("*")
        .eq("user_id", user_id)
        .eq("category", category)
        .eq("item", item)
        .execute()
    )
    if existing.data:
        pref = existing.data[0]
        supabase.table("user_preferences").update({
            "order_count": pref["order_count"] + 1,
            "last_ordered": datetime.now(timezone.utc).isoformat(),
        }).eq("preference_id", pref["preference_id"]).execute()
    else:
        supabase.table("user_preferences").insert({
            "user_id": user_id,
            "category": category,
            "item": item,
            "order_count": 1,
        }).execute()
