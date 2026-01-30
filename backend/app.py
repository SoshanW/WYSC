import os
from functools import lru_cache
from typing import Tuple

from flask import Flask, jsonify, request
from supabase import Client, create_client

app = Flask(__name__)

SUPABASE_TABLE = os.getenv("SUPABASE_TABLE", "profiles")


def _load_supabase_credentials() -> Tuple[str, str]:
    """Fetch Supabase credentials from the environment."""
    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_ANON_KEY")
    if not url or not key:
        raise RuntimeError(
            "Supabase credentials missing. Set SUPABASE_URL and SUPABASE_ANON_KEY."
        )
    return url, key


@lru_cache(maxsize=1)
def get_supabase_client() -> Client:
    """Create a Supabase client once and reuse it."""
    url, key = _load_supabase_credentials()
    return create_client(url, key)


@app.route("/", methods=["GET"])
def home():
    return jsonify({"message": "Flask API is running"})


@app.route("/hello", methods=["GET"])
def hello():
    name = request.args.get("name", "World")
    return jsonify({"message": f"Hello {name}!"})


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "OK"}), 200


@app.route("/records", methods=["GET"])
def list_records():
    """Return up to 100 rows from the configured Supabase table."""
    try:
        response = (
            get_supabase_client()
            .table(SUPABASE_TABLE)
            .select("*")
            .limit(100)
            .execute()
        )
        return jsonify({"data": response.data}), 200
    except Exception as exc:  # pragma: no cover - keep response simple
        return jsonify({"error": str(exc)}), 500


@app.route("/records", methods=["POST"])
def create_record():
    """Insert a JSON payload as a new row in Supabase."""
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
    except Exception as exc:  # pragma: no cover - keep response simple
        return jsonify({"error": str(exc)}), 500


@app.route("/supabase/health", methods=["GET"])
def supabase_health():
    """Ensure Supabase credentials are valid and the client can be created."""
    try:
        get_supabase_client()
        return jsonify({"status": "connected"}), 200
    except Exception as exc:
        return jsonify({"status": "error", "details": str(exc)}), 500


if __name__ == "__main__":
    app.run(debug=True)
