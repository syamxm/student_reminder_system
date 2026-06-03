import json
import logging
import os

from redis import asyncio as aioredis

log = logging.getLogger("cache")

_REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")

_client: aioredis.Redis | None = None


async def init_cache() -> None:
    global _client
    _client = aioredis.from_url(_REDIS_URL, decode_responses=True)
    try:
        await _client.ping()
        log.info("Redis connected at %s", _REDIS_URL)
    except Exception as e:
        log.warning("Redis unavailable, running fail-open: %s", e)


async def close_cache() -> None:
    if _client is not None:
        await _client.aclose()


def get_client() -> aioredis.Redis | None:
    return _client


async def get_json(key: str):
    """Return cached value or None on miss/any Redis error (fail open)."""
    if _client is None:
        return None
    try:
        raw = await _client.get(key)
        return json.loads(raw) if raw is not None else None
    except Exception as e:
        log.warning("cache get failed for %s: %s", key, e)
        return None


async def set_json(key: str, value, ttl_seconds: int) -> None:
    """Store value with TTL. No-op on any Redis error (fail open)."""
    if _client is None:
        return
    try:
        await _client.set(key, json.dumps(value), ex=ttl_seconds)
    except Exception as e:
        log.warning("cache set failed for %s: %s", key, e)
