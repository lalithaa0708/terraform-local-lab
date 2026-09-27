import os
from flask import Flask, jsonify

app = Flask(__name__)
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


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
