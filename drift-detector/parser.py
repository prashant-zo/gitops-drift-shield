import json
import subprocess
import logging

logger = logging.getLogger(__name__)

def run_terraform_plan(tf_dir: str) -> dict:
    try:
        result = subprocess.run(
            ["terraform", "plan", "-json", "-detailed-exitcode", "-no-color"],
            cwd=tf_dir,
            capture_output=True,
            text=True,
            timeout=300
        )

        plan_lines = [json.loads(line) for line in result.stdout.strip().split("\n") if line.strip()]

        return {
            "exit_code": result.returncode,
            "plan_lines": plan_lines,
            "stderr": result.stderr,
            "tf_dir": tf_dir
        }
    except Exception as e:
        logger.error(f"Failed to run terraform plan: {e}")
        raise

def parse_drift(plan_result: dict) -> dict:
    exit_code = plan_result["exit_code"]

    if exit_code == 0:
        return {"drift_detected": False, "changed_resources": [], "drift_count": 0, "summary": "Clean."}

    if exit_code == 1:
        return {"drift_detected": False, "changed_resources": [], "drift_count": 0, "summary": f"Error: {plan_result['stderr']}"}

    changed_resources = []
    for line in plan_result["plan_lines"]:
        if line.get("type") == "planned_change":
            change = line.get("change", {})
            resource = change.get("resource", {})
            changed_resources.append({
                "action": change.get("action", "unknown"),
                "address": resource.get("addr", "unknown")
            })

    return {
        "drift_detected": True,
        "changed_resources": changed_resources,
        "drift_count": len(changed_resources),
        "summary": f"Drift detection: {len(changed_resources)} resources changed!"
    }
