from functools import wraps

from flask import g, jsonify, request

from config import get_supabase_client


def require_auth(f):
    """Decorator that extracts and validates the Bearer token.

    On success, sets ``g.user_id`` to the authenticated user's UUID so
    route handlers can use it directly.
    """

    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get("Authorization", "")
        if not auth_header.startswith("Bearer "):
            return jsonify({"error": "Missing or invalid Authorization header."}), 401

        token = auth_header[7:]
        try:
            response = get_supabase_client().auth.get_user(token)
            g.user_id = response.user.id
        except Exception:
            return jsonify({"error": "Invalid or expired token."}), 401

        return f(*args, **kwargs)

    return decorated
