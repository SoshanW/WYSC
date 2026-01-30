import googlemaps

from config import GOOGLE_PLACES_API_KEY


def _get_gmaps_client():
    if not GOOGLE_PLACES_API_KEY:
        return None
    return googlemaps.Client(key=GOOGLE_PLACES_API_KEY)


def search_nearby_places(keyword: str, lat: float, lng: float, radius: int = 5000) -> list[dict]:
    """Search for places near *lat*/*lng* that match *keyword*.

    Returns a list of dicts with keys: name, address, place_id, rating.
    Returns an empty list when the API key is missing or the call fails.
    """
    client = _get_gmaps_client()
    if client is None:
        return []

    try:
        response = client.places_nearby(
            location=(lat, lng),
            radius=radius,
            keyword=keyword,
            type="food",
        )
        results = response.get("results", [])
        return [
            {
                "name": place.get("name", ""),
                "address": place.get("vicinity", ""),
                "place_id": place.get("place_id", ""),
                "rating": place.get("rating", 0),
            }
            for place in results[:10]  # cap at 10 places
        ]
    except Exception:
        return []
