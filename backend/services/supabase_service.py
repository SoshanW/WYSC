from __future__ import annotations

from typing import Any, Dict, Iterable, List, Optional, Tuple

from config import get_supabase_client


Filter = Tuple[str, str, Any]


class SupabaseService:
    """Lightweight data access wrapper for Supabase tables."""

    def __init__(self):
        self._client = get_supabase_client()

    def list(
        self,
        table: str,
        filters: Optional[Iterable[Filter]] = None,
        limit: int = 100,
        order_by: Optional[str] = None,
        desc: bool = False,
    ) -> List[Dict[str, Any]]:
        query = self._client.table(table).select("*")
        query = self._apply_filters(query, filters)
        if order_by:
            query = query.order(order_by, desc=desc)
        if limit:
            query = query.limit(int(limit))
        response = query.execute()
        return response.data or []

    def get_one(
        self,
        table: str,
        id_field: str,
        id_value: Any,
        filters: Optional[Iterable[Filter]] = None,
    ) -> Optional[Dict[str, Any]]:
        query = self._client.table(table).select("*")
        query = query.eq(id_field, id_value)
        query = self._apply_filters(query, filters)
        response = query.execute()
        return (response.data or [None])[0]

    def create(self, table: str, payload: Dict[str, Any]) -> Dict[str, Any]:
        response = self._client.table(table).insert(payload).execute()
        return response.data[0] if response.data else {}

    def update(
        self,
        table: str,
        id_field: str,
        id_value: Any,
        payload: Dict[str, Any],
        filters: Optional[Iterable[Filter]] = None,
    ) -> Dict[str, Any]:
        query = self._client.table(table).update(payload).eq(id_field, id_value)
        query = self._apply_filters(query, filters)
        response = query.execute()
        return response.data[0] if response.data else {}

    def delete(
        self,
        table: str,
        id_field: str,
        id_value: Any,
        filters: Optional[Iterable[Filter]] = None,
    ) -> Dict[str, Any]:
        query = self._client.table(table).delete().eq(id_field, id_value)
        query = self._apply_filters(query, filters)
        response = query.execute()
        return response.data[0] if response.data else {}

    @staticmethod
    def _apply_filters(query, filters: Optional[Iterable[Filter]]):
        if not filters:
            return query
        for field, op, value in filters:
            if op == "eq":
                query = query.eq(field, value)
            elif op == "lt":
                query = query.lt(field, value)
            elif op == "lte":
                query = query.lte(field, value)
            elif op == "gt":
                query = query.gt(field, value)
            elif op == "gte":
                query = query.gte(field, value)
            elif op == "neq":
                query = query.neq(field, value)
            elif op == "in":
                query = query.in_(field, value)
        return query