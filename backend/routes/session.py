from flask import Blueprint, g, jsonify, request

from config import get_supabase_client
from middleware.auth_middleware import require_auth
from models.enums import SessionType
from services import llm_service, places_service

session_bp = Blueprint("session", __name__)

MATURITY_THRESHOLD = 5  # preferences count to trigger personalisation


@session_bp.route("/crave", methods=["POST"])
@require_auth
def submit_crave():
    """Submit a craving and get specific options
    ---
    tags:
      - Session
    security:
      - Bearer: []
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          required:
            - crave_item
            - latitude
            - longitude
          properties:
            crave_item:
              type: string
              example: crepe
            latitude:
              type: number
              example: 6.9271
            longitude:
              type: number
              example: 79.8612
    responses:
      200:
        description: Craving options generated
      400:
        description: Missing required fields
      500:
        description: Server error
    """
    body = request.get_json(silent=True) or {}
    crave_item = body.get("crave_item")
    lat = body.get("latitude")
    lng = body.get("longitude")

    if not crave_item or lat is None or lng is None:
        return jsonify({"error": "crave_item, latitude and longitude are required."}), 400

    try:
        supabase = get_supabase_client()
        user_id = g.user_id

        # Check user preferences for this category
        prefs_resp = (
            supabase.table("user_preferences")
            .select("*")
            .eq("user_id", user_id)
            .eq("category", crave_item.lower())
            .execute()
        )
        preferences = prefs_resp.data or []
        is_personalized = len(preferences) >= MATURITY_THRESHOLD

        # Find nearby places
        places = places_service.search_nearby_places(crave_item, lat, lng)

        # Generate specific options via LLM
        try:
            options = llm_service.generate_craving_options(
                crave_item,
                places,
                user_preferences=preferences if is_personalized else None,
            )
        except Exception as llm_err:
            return jsonify({"error": f"LLM service error: {llm_err}"}), 502

        # Create session record
        session_resp = (
            supabase.table("sessions")
            .insert({
                "user_id": user_id,
                "crave_item": crave_item,
                "location_options": {"places": places, "options": options},
            })
            .execute()
        )
        session = session_resp.data[0]

        return jsonify({
            "data": {
                "session_id": session["session_id"],
                "options": options,
                "personalized": is_personalized,
            }
        }), 200

    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@session_bp.route("/select", methods=["POST"])
@require_auth
def select_option():
    """Select a craving option and get calorie estimate
    ---
    tags:
      - Session
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
            - selected_option
          properties:
            session_id:
              type: string
            selected_option:
              type: string
              example: Chocolate crepe from La Creperie
    responses:
      200:
        description: Option selected, calories estimated
      400:
        description: Missing fields
      404:
        description: Session not found
      500:
        description: Server error
    """
    body = request.get_json(silent=True) or {}
    session_id = body.get("session_id")
    selected_option = body.get("selected_option")

    if not session_id or not selected_option:
        return jsonify({"error": "session_id and selected_option are required."}), 400

    try:
        supabase = get_supabase_client()

        # Verify session belongs to user
        sess_resp = (
            supabase.table("sessions")
            .select("*")
            .eq("session_id", session_id)
            .eq("user_id", g.user_id)
            .execute()
        )
        if not sess_resp.data:
            return jsonify({"error": "Session not found."}), 404

        # Estimate calories via LLM
        try:
            calories = llm_service.estimate_calories(selected_option)
        except Exception as llm_err:
            return jsonify({"error": f"LLM service error: {llm_err}"}), 502

        # Update session
        supabase.table("sessions").update({
            "crave_item": selected_option,
            "calories": calories,
        }).eq("session_id", session_id).execute()

        return jsonify({
            "data": {
                "session_id": session_id,
                "selected_item": selected_option,
                "estimated_calories": calories,
                "session_types": [t.value for t in SessionType],
            }
        }), 200

    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@session_bp.route("/choose-type", methods=["POST"])
@require_auth
def choose_session_type():
    """Choose a session type (solo challenge, invite friend, etc.)
    ---
    tags:
      - Session
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
            - session_type
          properties:
            session_id:
              type: string
            session_type:
              type: string
              enum: [solo_challenge, invite_friend, challenge_random, skip]
    responses:
      200:
        description: Session type set. Returns challenges for solo_challenge.
      400:
        description: Invalid input
      404:
        description: Session not found
      500:
        description: Server error
    """
    body = request.get_json(silent=True) or {}
    session_id = body.get("session_id")
    session_type = body.get("session_type")

    if not session_id or not session_type:
        return jsonify({"error": "session_id and session_type are required."}), 400

    # Validate enum
    try:
        stype = SessionType(session_type)
    except ValueError:
        valid = [t.value for t in SessionType]
        return jsonify({"error": f"Invalid session_type. Must be one of: {valid}"}), 400

    try:
        supabase = get_supabase_client()

        # Verify session + get calories
        sess_resp = (
            supabase.table("sessions")
            .select("*")
            .eq("session_id", session_id)
            .eq("user_id", g.user_id)
            .execute()
        )
        if not sess_resp.data:
            return jsonify({"error": "Session not found."}), 404

        session = sess_resp.data[0]

        # Update session type
        supabase.table("sessions").update({
            "session_type": stype.value,
        }).eq("session_id", session_id).execute()

        if stype == SessionType.SOLO_CHALLENGE:
            # Fetch user profile for personalised challenges
            profile_resp = (
                supabase.table("profiles")
                .select("age, weight")
                .eq("user_id", g.user_id)
                .execute()
            )
            profile = profile_resp.data[0] if profile_resp.data else {}

            try:
                challenges = llm_service.generate_challenges(
                    calories=session.get("calories", 300),
                    user_age=profile.get("age"),
                    user_weight=profile.get("weight"),
                )
            except Exception as llm_err:
                return jsonify({"error": f"LLM service error: {llm_err}"}), 502

            return jsonify({
                "data": {
                    "session_id": session_id,
                    "session_type": stype.value,
                    "challenges": challenges,
                }
            }), 200

        if stype == SessionType.SKIP:
            return jsonify({
                "data": {
                    "session_id": session_id,
                    "session_type": stype.value,
                    "message": "Session skipped. No points earned.",
                }
            }), 200

        if stype == SessionType.INVITE_FRIEND:
            # Generate challenges for the inviter to pick from before creating invite
            profile_resp = (
                supabase.table("profiles")
                .select("age, weight")
                .eq("user_id", g.user_id)
                .execute()
            )
            profile = profile_resp.data[0] if profile_resp.data else {}

            try:
                challenges = llm_service.generate_challenges(
                    calories=session.get("calories", 300),
                    user_age=profile.get("age"),
                    user_weight=profile.get("weight"),
                )
            except Exception as llm_err:
                return jsonify({"error": f"LLM service error: {llm_err}"}), 502

            return jsonify({
                "data": {
                    "session_id": session_id,
                    "session_type": stype.value,
                    "challenges": challenges,
                    "message": "Select a challenge, then create an invite via POST /invite/create.",
                }
            }), 200

        if stype == SessionType.CHALLENGE_RANDOM:
            return jsonify({
                "data": {
                    "session_id": session_id,
                    "session_type": stype.value,
                    "message": "Session type set. Join the matchmaking queue via POST /match/queue.",
                }
            }), 200

        return jsonify({
            "data": {
                "session_id": session_id,
                "session_type": stype.value,
            }
        }), 200

    except Exception as exc:
        return jsonify({"error": str(exc)}), 500
