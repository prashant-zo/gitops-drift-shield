import os
import json
import logging
import requests
import time
from datetime import datetime, timezone
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway

logger = logging.getLogger(__name__)

COOLDOWN_FILE = "/tmp/drift_alert_state.json"
COOLDOWN_SECONDS = 1800

def push_drift_metric(drift_result: dict, environment: str, pushgateway_url: str):
    registry = CollectorRegistry()
    drift_detected = Gauge("infra_drift_detected", "1 if drift, 0 if clean", ["environment"], registry=registry)
    drift_count = Gauge("infra_drift_resource_count", "Number of drifted resources", ["environment"], registry=registry)

    drift_detected.labels(environment=environment).set(1 if drift_result["drift_detected"] else 0)
    drift_count.labels(environment=environment).set(drift_result["drift_count"])

    try:
        push_to_gateway(pushgateway_url, job="drift-detector", registry=registry)
    except Exception as e:
        logger.warning(f"Could not push metrics (Pushgateway might be offline): {e}")


def should_send_alert() -> bool:
    now = time.time()
    if os.path.exists(COOLDOWN_FILE):
        with open(COOLDOWN_FILE, "r") as f:
            data = json.load(f)
            last_alert = data.get("last_alert_time", 0)
            if now - last_alert < COOLDOWN_SECONDS:
                logger.info("In cooldown period. Skipping slack alert.")
                return False

    with open(COOLDOWN_FILE, "w") as f:
        json.dump({"last_alert_time": now}, f)
    return True

def send_slack_alert(drift_result: dict, environment: str, webhook_url):
    if not drift_result["drift_detected"] or not webhook_url:
        return

    if not should_send_alert():
        return

    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    changed_list = "\n".join([f"• `{r['address']}` — action: *{r['action']}*" for r in drift_result["changed_resources"]])

    payload = {
        "text": f":rotating_light: *Infrastructure Drift Detected — {environment}*",
        "attachments": [{
            "color": "#FF0000",
            "fields": [
                {"title": "Environment", "value": environment, "short": True},
                {"title": "Resources Affected", "value": str(drift_result["drift_count"]), "short": True},
                {"title": "Changed Resources", "value": changed_list, "short": False}
            ],
            "footer": f"Detected At: {timestamp}"
        }]
    }

    try:
        requests.post(webhook_url, json=payload, timeout=10)
        logger.info("Slack alert sent successfully!")
    except Exception as e:
        logger.error(f"Failed to send Slack alert: {e}")
