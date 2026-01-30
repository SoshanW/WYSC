from flask import Blueprint, g, jsonify, request

from config import get_supabase_client
from middleware.auth_middleware import require_auth

user_bp = Blueprint("user", __name__)


@user_bp.route("/profile", methods=["GET"])
@require_auth
def get_profile():
    """Get current user profile with rank
    ---
    tags:
      - User
    security:
      - Bearer: []
    responses:
      200:
        description: User profile with rank
      404:
        description: Profile not found
    """
    supabase = get_supabase_client()

    profile_resp = (
        supabase.table("profiles")
        .select("*")
        .eq("user_id", g.user_id)
        .execute()
    )
    if not profile_resp.data:
        return jsonify({"error": "Profile not found."}), 404

    profile = profile_resp.data[0]
    total_points = profile.get("total_points", 0)

    # Look up rank
    rank_resp = (
        supabase.table("ranks")
        .select("rank_type")
        .lte("min_points", total_points)
        .gte("max_points", total_points)
        .execute()
    )
    rank = rank_resp.data[0]["rank_type"] if rank_resp.data else "Beginner"

    return jsonify({
        "data": {
            "user_id": profile["user_id"],
            "name": profile.get("name"),
            "email": profile.get("email"),
            "age": profile.get("age"),
            "height": profile.get("height"),
            "weight": profile.get("weight"),
            "total_points": total_points,
            "rank": rank,
        }
    }), 200


@user_bp.route("/profile", methods=["PUT"])
@require_auth
def update_profile():
    """Update user profile (age, height, weight)
    ---
    tags:
      - User
    security:
      - Bearer: []
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          properties:
            name:
              type: string
              example: John Doe
            age:
              type: integer
              example: 25
            height:
              type: number
              example: 175.5
              description: Height in cm
            weight:
              type: number
              example: 70.0
              description: Weight in kg
    responses:
      200:
        description: Profile updated
      400:
        description: No valid fields provided
    """
    body = request.get_json(silent=True) or {}
    allowed_fields = {"name", "age", "height", "weight"}
    updates = {k: v for k, v in body.items() if k in allowed_fields and v is not None}

    if not updates:
        return jsonify({"error": "No valid fields to update. Allowed: name, age, height, weight."}), 400

    supabase = get_supabase_client()
    supabase.table("profiles").update(updates).eq("user_id", g.user_id).execute()

    return jsonify({
        "data": {"message": "Profile updated.", "updated_fields": list(updates.keys())}
    }), 200


@user_bp.route("/history", methods=["GET"])
@require_auth
def get_history():
    """Get session history with challenges
    ---
    tags:
      - User
    security:
      - Bearer: []
    responses:
      200:
        description: List of past sessions with challenges
    """
    supabase = get_supabase_client()

    sessions_resp = (
        supabase.table("sessions")
        .select("*, challenges(*)")
        .eq("user_id", g.user_id)
        .order("created_at", desc=True)
        .limit(50)
        .execute()
    )

    sessions = sessions_resp.data or []

    return jsonify({
        "data": {
            "sessions": [
                {
                    "session_id": s["session_id"],
                    "crave_item": s["crave_item"],
                    "calories": s.get("calories"),
                    "session_type": s.get("session_type"),
                    "rating": s.get("rating"),
                    "created_at": s.get("created_at"),
                    "challenges": s.get("challenges", []),
                }
                for s in sessions
            ]
        }
    }), 200
