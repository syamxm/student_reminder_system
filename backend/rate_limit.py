import logging

from fastapi import Depends, HTTPException

from auth import require_uid
from cache import get_client

log = logging.getLogger("rate_limit")


def RateLimit(name: str, times: int, seconds: int):
    """Build a per-uid fixed-window rate-limit dependency.

    Allows `times` requests per `seconds` window per Firebase uid on the
    `name` route. Fails open: any Redis error lets the request through.
    """

    async def dependency(uid: str = Depends(require_uid)) -> str:
        client = get_client()
        if client is None:
            return uid

        key = f"rl:{name}:{uid}"
        try:
            async with client.pipeline(transaction=True) as pipe:
                pipe.incr(key)
                pipe.expire(key, seconds, nx=True)
                count, _ = await pipe.execute()
        except Exception as e:
            log.warning("rate limit check failed for %s: %s", key, e)
            return uid

        if count > times:
            raise HTTPException(status_code=429, detail="rate_limited")
        return uid

    return dependency
