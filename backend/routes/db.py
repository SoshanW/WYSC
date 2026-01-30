from flask import Blueprint, g, jsonify, request

from middleware.auth_middleware import require_auth
from services.supabase_service import SupabaseService

db_bp = Blueprint("db", __name__)


def _service() -> SupabaseService:
    return SupabaseService()


def _limit_from_args(default: int = 100) -> int:
    try:
        return int(request.args.get("limit", default))
    except (TypeError, ValueError):
        return default


def _order_from_args():
    order_by = request.args.get("order_by")
    desc = request.args.get("desc", "false").lower() == "true"
    return order_by, desc


# -------------------- Profiles --------------------


@db_bp.route("/profiles", methods=["GET"])
@require_auth
def list_profiles():
    """List current user's profile
    ---
    tags:
      - CRUD
    security:
      - Bearer: []
    """
    order_by, desc = _order_from_args()
    data = _service().list(
        "profiles",
        filters=[("user_id", "eq", g.user_id)],
        limit=_limit_from_args(),
        order_by=order_by,
        desc=desc,
    )
    return jsonify({"data": data}), 200


@db_bp.route("/profiles/<user_id>", methods=["GET"])
@require_auth
def get_profile(user_id: str):
    if user_id != g.user_id:
        return jsonify({"error": "Forbidden."}), 403
    data = _service().get_one("profiles", "user_id", user_id)
    if not data:
        return jsonify({"error": "Profile not found."}), 404
    return jsonify({"data": data}), 200


@db_bp.route("/profiles", methods=["POST"])
@require_auth
def create_profile():
    body = request.get_json(silent=True) or {}
    body["user_id"] = g.user_id
    created = _service().create("profiles", body)
    return jsonify({"data": created}), 201


@db_bp.route("/profiles/<user_id>", methods=["PUT", "PATCH"])
@require_auth
def update_profile(user_id: str):
    if user_id != g.user_id:
        return jsonify({"error": "Forbidden."}), 403
    body = request.get_json(silent=True) or {}
    if not body:
        return jsonify({"error": "Request body must be valid JSON."}), 400
    updated = _service().update("profiles", "user_id", user_id, body)
    if not updated:
        return jsonify({"error": "Profile not found."}), 404
    return jsonify({"data": updated}), 200


@db_bp.route("/profiles/<user_id>", methods=["DELETE"])
@require_auth
def delete_profile(user_id: str):
    if user_id != g.user_id:
        return jsonify({"error": "Forbidden."}), 403
    deleted = _service().delete("profiles", "user_id", user_id)
    if not deleted:
        return jsonify({"error": "Profile not found."}), 404
    return jsonify({"data": deleted}), 200


# -------------------- Sessions --------------------


@db_bp.route("/sessions", methods=["GET"])
@require_auth
def list_sessions():
    order_by, desc = _order_from_args()
    data = _service().list(
        "sessions",
        filters=[("user_id", "eq", g.user_id)],
        limit=_limit_from_args(),
        order_by=order_by,
        desc=desc,
    )
    return jsonify({"data": data}), 200


@db_bp.route("/sessions/<session_id>", methods=["GET"])
@require_auth
def get_session(session_id: str):
    data = _service().get_one(
        "sessions",
        "session_id",
        session_id,
        filters=[("user_id", "eq", g.user_id)],
    )
    if not data:
        return jsonify({"error": "Session not found."}), 404
    return jsonify({"data": data}), 200


@db_bp.route("/sessions", methods=["POST"])
@require_auth
def create_session():
    body = request.get_json(silent=True) or {}
    body["user_id"] = g.user_id
    created = _service().create("sessions", body)
    return jsonify({"data": created}), 201


@db_bp.route("/sessions/<session_id>", methods=["PUT", "PATCH"])
@require_auth
def update_session(session_id: str):
    body = request.get_json(silent=True) or {}
    if not body:
        return jsonify({"error": "Request body must be valid JSON."}), 400
    updated = _service().update(
        "sessions",
        "session_id",
        session_id,
        body,
        filters=[("user_id", "eq", g.user_id)],
    )
    if not updated:
        return jsonify({"error": "Session not found."}), 404
    return jsonify({"data": updated}), 200


@db_bp.route("/sessions/<session_id>", methods=["DELETE"])
@require_auth
def delete_session(session_id: str):
    deleted = _service().delete(
        "sessions",
        "session_id",
        session_id,
        filters=[("user_id", "eq", g.user_id)],
    )
    if not deleted:
        return jsonify({"error": "Session not found."}), 404
    return jsonify({"data": deleted}), 200


# -------------------- Challenges --------------------


@db_bp.route("/challenges", methods=["GET"])
@require_auth
def list_challenges():
    order_by, desc = _order_from_args()
    session_id = request.args.get("session_id")
    filters = []
    if session_id:
        filters.append(("session_id", "eq", session_id))
    data = _service().list(
        "challenges",
        filters=filters,
        limit=_limit_from_args(),
        order_by=order_by,
        desc=desc,
    )
    return jsonify({"data": data}), 200


@db_bp.route("/challenges/<challenge_id>", methods=["GET"])
@require_auth
def get_challenge(challenge_id: str):
    data = _service().get_one("challenges", "challenge_id", challenge_id)
    if not data:
        return jsonify({"error": "Challenge not found."}), 404
    return jsonify({"data": data}), 200


@db_bp.route("/challenges", methods=["POST"])
@require_auth
def create_challenge():
    body = request.get_json(silent=True) or {}
    session_id = body.get("session_id")
    if not session_id:
        return jsonify({"error": "session_id is required."}), 400
    session = _service().get_one(
        "sessions",
        "session_id",
        session_id,
        filters=[("user_id", "eq", g.user_id)],
    )
    if not session:
        return jsonify({"error": "Session not found."}), 404
    created = _service().create("challenges", body)
    return jsonify({"data": created}), 201


@db_bp.route("/challenges/<challenge_id>", methods=["PUT", "PATCH"])
@require_auth
def update_challenge(challenge_id: str):
    body = request.get_json(silent=True) or {}
    if not body:
        return jsonify({"error": "Request body must be valid JSON."}), 400
    updated = _service().update("challenges", "challenge_id", challenge_id, body)
    if not updated:
        return jsonify({"error": "Challenge not found."}), 404
    return jsonify({"data": updated}), 200


@db_bp.route("/challenges/<challenge_id>", methods=["DELETE"])
@require_auth
def delete_challenge(challenge_id: str):
    deleted = _service().delete("challenges", "challenge_id", challenge_id)
    if not deleted:
        return jsonify({"error": "Challenge not found."}), 404
    return jsonify({"data": deleted}), 200


# -------------------- Ranks --------------------


@db_bp.route("/ranks", methods=["GET"])
def list_ranks():
    order_by, desc = _order_from_args()
    data = _service().list(
        "ranks",
        limit=_limit_from_args(),
        order_by=order_by,
        desc=desc,
    )
    return jsonify({"data": data}), 200


@db_bp.route("/ranks/<int:rank_id>", methods=["GET"])
def get_rank(rank_id: int):
    data = _service().get_one("ranks", "rank_id", rank_id)
    if not data:
        return jsonify({"error": "Rank not found."}), 404
    return jsonify({"data": data}), 200


@db_bp.route("/ranks", methods=["POST"])
@require_auth
def create_rank():
    body = request.get_json(silent=True) or {}
    created = _service().create("ranks", body)
    return jsonify({"data": created}), 201


@db_bp.route("/ranks/<int:rank_id>", methods=["PUT", "PATCH"])
@require_auth
def update_rank(rank_id: int):
    body = request.get_json(silent=True) or {}
    if not body:
        return jsonify({"error": "Request body must be valid JSON."}), 400
    updated = _service().update("ranks", "rank_id", rank_id, body)
    if not updated:
        return jsonify({"error": "Rank not found."}), 404
    return jsonify({"data": updated}), 200


@db_bp.route("/ranks/<int:rank_id>", methods=["DELETE"])
@require_auth
def delete_rank(rank_id: int):
    deleted = _service().delete("ranks", "rank_id", rank_id)
    if not deleted:
        return jsonify({"error": "Rank not found."}), 404
    return jsonify({"data": deleted}), 200


# -------------------- User Preferences --------------------


@db_bp.route("/preferences", methods=["GET"])
@require_auth
def list_preferences():
    order_by, desc = _order_from_args()
    data = _service().list(
        "user_preferences",
        filters=[("user_id", "eq", g.user_id)],
        limit=_limit_from_args(),
        order_by=order_by,
        desc=desc,
    )
    return jsonify({"data": data}), 200


@db_bp.route("/preferences/<preference_id>", methods=["GET"])
@require_auth
def get_preference(preference_id: str):
    data = _service().get_one(
        "user_preferences",
        "preference_id",
        preference_id,
        filters=[("user_id", "eq", g.user_id)],
    )
    if not data:
        return jsonify({"error": "Preference not found."}), 404
    return jsonify({"data": data}), 200


@db_bp.route("/preferences", methods=["POST"])
@require_auth
def create_preference():
    body = request.get_json(silent=True) or {}
    body["user_id"] = g.user_id
    created = _service().create("user_preferences", body)
    return jsonify({"data": created}), 201


@db_bp.route("/preferences/<preference_id>", methods=["PUT", "PATCH"])
@require_auth
def update_preference(preference_id: str):
    body = request.get_json(silent=True) or {}
    if not body:
        return jsonify({"error": "Request body must be valid JSON."}), 400
    updated = _service().update(
        "user_preferences",
        "preference_id",
        preference_id,
        body,
        filters=[("user_id", "eq", g.user_id)],
    )
    if not updated:
        return jsonify({"error": "Preference not found."}), 404
    return jsonify({"data": updated}), 200


@db_bp.route("/preferences/<preference_id>", methods=["DELETE"])
@require_auth
def delete_preference(preference_id: str):
    deleted = _service().delete(
        "user_preferences",
        "preference_id",
        preference_id,
        filters=[("user_id", "eq", g.user_id)],
    )
    if not deleted:
        return jsonify({"error": "Preference not found."}), 404
    return jsonify({"data": deleted}), 200