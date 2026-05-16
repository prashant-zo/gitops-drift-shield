#!/usr/bin/env python3
import argparse
import logging
import os
import sys
from pathlib import Path

from parser import run_terraform_plan, parse_drift
from notifier import push_drift_metric, send_slack_alert

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s]: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)
logger = logging.getLogger("drift-detector")

def main():
    arg_parser = argparse.ArgumentParser(description="GitOps Drift Shield")
    arg_parser.add_argument("--env", default="dev", help="Environment name (dev/prod)")
    args = arg_parser.parse_args()

    environment = args.env
    tf_dir = str(Path(__file__).parent.parent / "terraform" / "environments" / environment)

    pushgateway_url = os.getenv("PUSHGATEWAY_URL", "http://localhost:9091")
    slack_webhook = os.getenv("SLACK_WEBHOOK_URL", "")

    logger.info(f"Starting drift check for {environment}...")

    plan_result = run_terraform_plan(tf_dir)

    drift_result = parse_drift(plan_result)
    logger.info(drift_result["summary"])

    push_drift_metric(drift_result, environment, pushgateway_url)

    if drift_result["drift_detected"]:
        if slack_webhook:
            send_slack_alert(drift_result, environment, slack_webhook)
        else:
            logger.warning("Slack Webhook URL not found. Skipping alert.")

        sys.exit(1)

    sys.exit(0)

if __name__ == "__main__":
    main()
