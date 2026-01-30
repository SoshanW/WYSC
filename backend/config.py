import os
from functools import lru_cache
from typing import Tuple

from dotenv import load_dotenv
from supabase import Client, create_client

load_dotenv()

SUPABASE_TABLE = os.getenv("SUPABASE_TABLE", "profiles")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
GOOGLE_PLACES_API_KEY = os.getenv("GOOGLE_PLACES_API_KEY")


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
