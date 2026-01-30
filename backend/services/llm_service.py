import json

from openai import OpenAI

from config import OPENAI_API_KEY

_client = OpenAI(api_key=OPENAI_API_KEY) if OPENAI_API_KEY else None

MODEL = "gpt-4o-mini"


def _chat(system_prompt: str, user_prompt: str) -> str:
    """Low-level helper that calls OpenAI chat completions."""
    if _client is None:
        raise RuntimeError("OPENAI_API_KEY is not configured.")
    response = _client.chat.completions.create(
        model=MODEL,
        temperature=0.7,
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
    )
    return response.choices[0].message.content


def _parse_json(text: str):
    """Extract and parse JSON from an LLM response that may contain markdown fences."""
    text = text.strip()
    if text.startswith("```"):
        # strip ```json ... ```
        lines = text.split("\n")
        lines = [l for l in lines if not l.strip().startswith("```")]
        text = "\n".join(lines)
    return json.loads(text)


# ------------------------------------------------------------------
# 1. Generate craving options from places + optional preferences
# ------------------------------------------------------------------

def generate_craving_options(
    crave_item: str,
    places: list[dict],
    user_preferences: list[dict] | None = None,
) -> list[dict]:
    """Return a list of specific craving options based on nearby places.

    Each option is a dict with keys: option (str), store (str), description (str).
    """
    system_prompt = (
        "You are a food craving assistant. The user has a generic craving. "
        "Based on the nearby stores provided, generate 4-6 specific options "
        "the user can choose from. Each option should be a specific menu item "
        "that satisfies the craving, tied to a real store from the list.\n\n"
        "Return ONLY a JSON array where each element has:\n"
        '  "option": specific item name,\n'
        '  "store": store name from the list,\n'
        '  "description": one-sentence description.\n\n'
        "No markdown, no explanation — just the JSON array."
    )

    places_text = "\n".join(
        f"- {p['name']} ({p['address']}, rating: {p['rating']})"
        for p in places
    ) if places else "No nearby stores found. Generate generic options instead."

    user_msg = f"Craving: {crave_item}\n\nNearby stores:\n{places_text}"

    if user_preferences:
        prefs_text = "\n".join(
            f"- {p['item']} (ordered {p['order_count']} times)"
            for p in user_preferences
        )
        user_msg += (
            f"\n\nThis user has ordered similar items before. "
            f"Prioritise options aligned with their history:\n{prefs_text}"
        )

    raw = _chat(system_prompt, user_msg)
    try:
        return _parse_json(raw)
    except (json.JSONDecodeError, ValueError):
        # Fallback: return a single generic option
        return [{"option": crave_item, "store": "Any nearby store", "description": f"A {crave_item}"}]


# ------------------------------------------------------------------
# 2. Estimate calories for a specific item
# ------------------------------------------------------------------

def estimate_calories(item_description: str) -> int:
    """Return an estimated calorie count for the given food item."""
    system_prompt = (
        "You are a nutrition assistant. Estimate the calorie count for the "
        "given food item. Return ONLY a JSON object with a single key "
        '"calories" whose value is an integer.\n'
        "Example: {\"calories\": 350}\n"
        "No markdown, no explanation — just the JSON object."
    )
    raw = _chat(system_prompt, f"Food item: {item_description}")
    try:
        data = _parse_json(raw)
        return int(data["calories"])
    except (json.JSONDecodeError, ValueError, KeyError):
        return 300  # safe fallback


# ------------------------------------------------------------------
# 3. Generate physical challenges based on calories & user profile
# ------------------------------------------------------------------

def generate_challenges(
    calories: int,
    user_age: int | None = None,
    user_weight: float | None = None,
) -> list[dict]:
    """Return 3 physical challenges calibrated to burn roughly *calories*.

    Each challenge is a dict with keys: description (str), time_limit (int, minutes).
    """
    system_prompt = (
        "You are a fitness challenge creator. The user wants to earn a food "
        "treat by completing a physical challenge. Generate exactly 3 challenges "
        "of varying difficulty (easy, medium, hard) that roughly burn the "
        "given calorie amount.\n\n"
        "For each challenge include:\n"
        '  "description": clear instructions on what to do,\n'
        '  "time_limit": duration in minutes.\n\n'
        "Return ONLY a JSON array of 3 objects. No markdown, no explanation."
    )

    user_msg = f"Target calorie burn: {calories} kcal"
    if user_age:
        user_msg += f"\nUser age: {user_age}"
    if user_weight:
        user_msg += f"\nUser weight: {user_weight} kg"

    raw = _chat(system_prompt, user_msg)
    try:
        challenges = _parse_json(raw)
        if isinstance(challenges, list) and len(challenges) >= 1:
            return challenges[:3]
    except (json.JSONDecodeError, ValueError):
        pass

    # Fallback challenges
    return [
        {"description": f"Take a brisk walk to burn ~{calories} kcal", "time_limit": 30},
        {"description": f"Do a light jog to burn ~{calories} kcal", "time_limit": 20},
        {"description": f"Bodyweight exercises (squats, push-ups, lunges) to burn ~{calories} kcal", "time_limit": 15},
    ]
