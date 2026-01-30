from flask import Blueprint, jsonify, request
from config import get_supabase_client

auth_bp = Blueprint("auth", __name__)


@auth_bp.route("/signup", methods=["POST"])
def signup():
    """Create a new account
    ---
    tags:
      - Auth
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          required:
            - email
            - password
          properties:
            email:
              type: string
              example: user@example.com
            password:
              type: string
              example: mypassword123
            name:
              type: string
              example: John Doe
    responses:
      201:
        description: Account created successfully
      400:
        description: Missing fields or signup failed
    """
    body = request.get_json(silent=True) or {}
    email = body.get("email")
    password = body.get("password")
    name = body.get("name", "")

    if not email or not password:
        return jsonify({"error": "Email and password are required."}), 400

    try:
        response = get_supabase_client().auth.sign_up(
            {
                "email": email,
                "password": password,
                "options": {
                    "data": {
                        "full_name": name,
                    }
                },
            }
        )

        result = {
            "user": {
                "id": response.user.id,
                "email": response.user.email,
                "full_name": name,
            },
        }

        if response.session:
            result["session"] = {
                "access_token": response.session.access_token,
                "refresh_token": response.session.refresh_token,
            }
        else:
            # Supabase has email confirmation enabled.
            # Auto-login the user so they get a token immediately.
            try:
                login_resp = get_supabase_client().auth.sign_in_with_password(
                    {"email": email, "password": password}
                )
                result["session"] = {
                    "access_token": login_resp.session.access_token,
                    "refresh_token": login_resp.session.refresh_token,
                }
            except Exception:
                result["session"] = None
                result["message"] = (
                    "Account created but email confirmation may be required. "
                    "Check your email or disable 'Confirm email' in Supabase "
                    "Dashboard > Authentication > Providers > Email."
                )

        return jsonify({"data": result}), 201

    except Exception as exc:
        return jsonify({"error": str(exc)}), 400


@auth_bp.route("/login", methods=["POST"])
def login():
    """Sign in with email and password
    ---
    tags:
      - Auth
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          required:
            - email
            - password
          properties:
            email:
              type: string
              example: user@example.com
            password:
              type: string
              example: mypassword123
    responses:
      200:
        description: Login successful, returns user and session tokens
      401:
        description: Invalid credentials
    """
    body = request.get_json(silent=True) or {}
    email = body.get("email")
    password = body.get("password")

    if not email or not password:
        return jsonify({"error": "Email and password are required."}), 400

    try:
        response = get_supabase_client().auth.sign_in_with_password(
            {"email": email, "password": password}
        )

        return jsonify({
            "data": {
                "user": {
                    "id": response.user.id,
                    "email": response.user.email,
                    "full_name": response.user.user_metadata.get("full_name", ""),
                },
                "session": {
                    "access_token": response.session.access_token,
                    "refresh_token": response.session.refresh_token,
                },
            }
        }), 200

    except Exception as exc:
        return jsonify({"error": str(exc)}), 401


@auth_bp.route("/logout", methods=["POST"])
def logout():
    """Sign out the current user
    ---
    tags:
      - Auth
    security:
      - Bearer: []
    responses:
      200:
        description: Logged out successfully
      401:
        description: Missing or invalid token
    """
    token = _extract_token()
    if not token:
        return jsonify({"error": "Missing Authorization header."}), 401

    try:
        # Validate the token is real before confirming logout
        get_supabase_client().auth.get_user(token)
        # For a stateless API the client discards the token.
        # Supabase JWTs expire naturally; there is no server-side
        # revocation with the anon key.
        return jsonify({"data": {"message": "Logged out successfully."}}), 200
    except Exception as exc:
        return jsonify({"error": str(exc)}), 401


@auth_bp.route("/me", methods=["GET"])
def me():
    """Get current user info
    ---
    tags:
      - Auth
    security:
      - Bearer: []
    responses:
      200:
        description: Current user details
      401:
        description: Missing or invalid token
    """
    token = _extract_token()
    if not token:
        return jsonify({"error": "Missing Authorization header."}), 401

    try:
        response = get_supabase_client().auth.get_user(token)
        user = response.user

        return jsonify({
            "data": {
                "id": user.id,
                "email": user.email,
                "full_name": user.user_metadata.get("full_name", ""),
                "created_at": str(user.created_at) if user.created_at else None,
            }
        }), 200

    except Exception as exc:
        return jsonify({"error": str(exc)}), 401


def _extract_token() -> str | None:
    """Pull the Bearer token from the Authorization header."""
    auth_header = request.headers.get("Authorization", "")
    if not auth_header:
        return None
    # Accept both "Bearer <token>" and raw "<token>"
    return auth_header[7:] if auth_header.startswith("Bearer ") else auth_header
