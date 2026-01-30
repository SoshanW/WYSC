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
        schema:
          type: object
          properties:
            data:
              type: object
              properties:
                user:
                  type: object
                  properties:
                    id:
                      type: string
                    email:
                      type: string
                    full_name:
                      type: string
                session:
                  type: object
                  properties:
                    access_token:
                      type: string
                    refresh_token:
                      type: string
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

        return jsonify({
            "data": {
                "user": {
                    "id": response.user.id,
                    "email": response.user.email,
                    "full_name": name,
                },
                "session": {
                    "access_token": response.session.access_token,
                    "refresh_token": response.session.refresh_token,
                } if response.session else None,
            }
        }), 201

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
        schema:
          type: object
          properties:
            data:
              type: object
              properties:
                user:
                  type: object
                  properties:
                    id:
                      type: string
                    email:
                      type: string
                    full_name:
                      type: string
                session:
                  type: object
                  properties:
                    access_token:
                      type: string
                    refresh_token:
                      type: string
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
        get_supabase_client().auth.sign_out(token)
        return jsonify({"data": {"message": "Logged out successfully."}}), 200
    except Exception as exc:
        return jsonify({"error": str(exc)}), 400


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
        schema:
          type: object
          properties:
            data:
              type: object
              properties:
                id:
                  type: string
                email:
                  type: string
                full_name:
                  type: string
                created_at:
                  type: string
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
                "created_at": user.created_at,
            }
        }), 200

    except Exception as exc:
        return jsonify({"error": str(exc)}), 401


def _extract_token() -> str | None:
    """Pull the Bearer token from the Authorization header."""
    auth_header = request.headers.get("Authorization", "")
    if auth_header.startswith("Bearer "):
        return auth_header[7:]
    return None
