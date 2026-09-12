import os
import time
from collections import defaultdict

from fastapi import HTTPException, Request, status

from app.core.config import settings


class SimpleRateLimiter:
    def __init__(self, requests_per_minute: int = 20) -> None:
        self.requests_per_minute = requests_per_minute
        self.ip_history: dict[str, list[float]] = defaultdict(list)

    def check_rate_limit(self, request: Request) -> None:
        # Disable rate limiting during automated testing or testclient execution
        if os.getenv("TESTING") == "true" or settings.ENVIRONMENT == "testing" or (request.client and request.client.host == "testclient"):
            return

        client_ip = request.client.host if request.client else "127.0.0.1"
        now = time.time()
        window_start = now - 60.0

        # Filter timestamps within the 60-second window
        timestamps = [t for t in self.ip_history[client_ip] if t > window_start]
        self.ip_history[client_ip] = timestamps

        if len(timestamps) >= self.requests_per_minute:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many requests. Please try again later.",
            )

        self.ip_history[client_ip].append(now)


rate_limiter_auth = SimpleRateLimiter(requests_per_minute=15)
rate_limiter_reports = SimpleRateLimiter(requests_per_minute=10)
