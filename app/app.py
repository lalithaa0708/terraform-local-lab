import os
from flask import Flask, jsonify

app = Flask(__name__)
from prometheus_flask_exporter import PrometheusMetrics
metrics = PrometheusMetrics(app)
VERSION = os.getenv("APP_VERSION", "1.0.0")
BROKEN = os.getenv("BREAK_HEALTH", "false").lower() == "true"


@app.route("/")
def index():
    return f"<h1>App v{VERSION}</h1><p>Environment: {os.getenv('ENV_NAME', 'dev')}</p>"


@app.route("/health")
def health():
    if BROKEN:
        return jsonify(status="unhealthy", version=VERSION), 500
    return jsonify(status="healthy", version=VERSION), 200
@app.route("/error")
def error():
    """Deliberate 500 for testing alerts. Readiness ignores this path,
    so pods stay in service and the errors actually reach users."""
    return jsonify(error="injected failure"), 500


@app.route("/slow")
def slow():
    """Deliberate latency for testing the latency SLO."""
    import time
    time.sleep(0.5)
    return jsonify(status="slow but fine"), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
