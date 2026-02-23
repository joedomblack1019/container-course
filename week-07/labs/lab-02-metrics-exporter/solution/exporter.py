"""
Prometheus metrics exporter for the course app.

Reads state from Redis and exposes /metrics in Prometheus format.
This is a read-only exporter — it should never modify Redis.
"""

from flask import Flask
import os
import redis
from prometheus_client import Gauge, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

# Redis configuration — same env vars as your app (Week 5)
REDIS_HOST = os.environ.get("REDIS_HOST", "localhost")
REDIS_PORT = int(os.environ.get("REDIS_PORT", 6379))
REDIS_PASSWORD = os.environ.get("REDIS_PASSWORD", "")

# Define Prometheus metrics
visits_gauge = Gauge("course_visits_total", "Total visit count per student", ["student"])
guestbook_gauge = Gauge(
    "course_guestbook_comments", "Number of guestbook comments per student", ["student"]
)


def get_redis():
    """Create a Redis connection. Returns None if unavailable."""
    try:
        r = redis.Redis(
            host=REDIS_HOST,
            port=REDIS_PORT,
            password=REDIS_PASSWORD or None,
            decode_responses=True,
            socket_connect_timeout=2,
        )
        r.ping()
        return r
    except (redis.ConnectionError, redis.TimeoutError):
        return None


def collect_metrics():
    """Read current state from Redis and update Prometheus gauges."""
    r = get_redis()
    if not r:
        return

    # Collect visit counts — keys are visits:<username>
    for key in r.scan_iter(match="visits:*"):
        student = key.split(":", 1)[1]
        count = int(r.get(key) or 0)
        visits_gauge.labels(student=student).set(count)

    # Collect guestbook counts — keys are guestbook:<username>
    for key in r.scan_iter(match="guestbook:*"):
        student = key.split(":", 1)[1]
        count = r.llen(key)
        guestbook_gauge.labels(student=student).set(count)


@app.route("/metrics")
def metrics():
    """Collect metrics from Redis and return in Prometheus format."""
    collect_metrics()
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


@app.route("/health")
def health():
    r = get_redis()
    return {"status": "healthy", "redis": "connected" if r else "disconnected"}


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 9100))
    print(f"Metrics exporter starting on port {port}")
    print(f"Redis: {REDIS_HOST}:{REDIS_PORT}")
    app.run(host="0.0.0.0", port=port)
