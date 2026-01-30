from flask import Flask, jsonify, request
from flask_cors import CORS
from flasgger import Swagger

from config import get_supabase_client, SUPABASE_TABLE
from routes.auth import auth_bp
from routes.session import session_bp
from routes.challenge import challenge_bp
from routes.user import user_bp
from routes.invite import invite_bp
from routes.match import match_bp

app = Flask(__name__)
CORS(app)

swagger_config = {
    "headers": [],
    "specs": [
        {
            "endpoint": "apispec",
            "route": "/apispec.json",
            "rule_filter": lambda rule: True,
            "model_filter": lambda tag: True,
        }
    ],
    "static_url_path": "/flasgger_static",
    "swagger_ui": True,
    "specs_route": "/apidocs/",
}

swagger_template = {
    "info": {
        "title": "CraveBalance API",
        "description": "Backend API for CraveBalance - manage cravings, auth, and data.",
        "version": "1.0.0",
    },
    "securityDefinitions": {
        "Bearer": {
            "type": "apiKey",
            "name": "Authorization",
            "in": "header",
            "description": "Paste your token with the Bearer prefix. Example: Bearer eyJhbGciOi...",
        }
    },
}

Swagger(app, config=swagger_config, template=swagger_template)

# Register blueprints
app.register_blueprint(auth_bp, url_prefix="/auth")
app.register_blueprint(session_bp, url_prefix="/session")
app.register_blueprint(challenge_bp, url_prefix="/challenge")
app.register_blueprint(user_bp, url_prefix="/user")
app.register_blueprint(invite_bp, url_prefix="/invite")
app.register_blueprint(match_bp, url_prefix="/match")


@app.route("/", methods=["GET"])
def home():
    """API welcome endpoint
    ---
    tags:
      - General
    responses:
      200:
        description: API is running
    """
    return jsonify({"message": "Flask API is running"})


@app.route("/hello", methods=["GET"])
def hello():
    """Say hello
    ---
    tags:
      - General
    parameters:
      - name: name
        in: query
        type: string
        required: false
        default: World
        description: Name to greet
    responses:
      200:
        description: Greeting message
    """
    name = request.args.get("name", "World")
    return jsonify({"message": f"Hello {name}!"})


@app.route("/health", methods=["GET"])
def health():
    """Health check
    ---
    tags:
      - General
    responses:
      200:
        description: API is healthy
    """
    return jsonify({"status": "OK"}), 200


@app.route("/records", methods=["GET"])
def list_records():
    """List records from Supabase
    ---
    tags:
      - Records
    responses:
      200:
        description: Up to 100 rows from the configured table
      500:
        description: Supabase error
    """
    try:
        response = (
            get_supabase_client()
            .table(SUPABASE_TABLE)
            .select("*")
            .limit(100)
            .execute()
        )
        return jsonify({"data": response.data}), 200
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@app.route("/records", methods=["POST"])
def create_record():
    """Insert a record into Supabase
    ---
    tags:
      - Records
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          description: JSON payload matching your table columns
    responses:
      201:
        description: Record created
      400:
        description: Invalid JSON body
      500:
        description: Supabase error
    """
    payload = request.get_json(silent=True) or {}
    if not payload:
        return jsonify({"error": "Request body must be valid JSON."}), 400

    try:
        response = (
            get_supabase_client()
            .table(SUPABASE_TABLE)
            .insert(payload)
            .execute()
        )
        return jsonify({"data": response.data}), 201
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@app.route("/supabase/health", methods=["GET"])
def supabase_health():
    """Supabase connection check
    ---
    tags:
      - General
    responses:
      200:
        description: Supabase client is connected
      500:
        description: Supabase connection failed
    """
    try:
        get_supabase_client()
        return jsonify({"status": "connected"}), 200
    except Exception as exc:
        return jsonify({"status": "error", "details": str(exc)}), 500


if __name__ == "__main__":
    app.run(debug=True)
