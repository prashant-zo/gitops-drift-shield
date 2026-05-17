#!/usr/bin/env bash
set -euo pipefail

echo "=== GitOps Drift Shield — End-to-End Test ==="
echo ""

ENVIRONMENT="dev"
TF_DIR="terraform/environments/${ENVIRONMENT}"
SG_ID=$(terraform -chdir="$TF_DIR" output -raw security_group_id)

rm -f /tmp/drift_alert_state.json

echo "Step 1: Verify baseline — no drift expected"
python3 drift-detector/detector.py --env "$ENVIRONMENT" && echo "✅ PASS: No drift" || echo "❌ UNEXPECTED: Drift found at baseline"

echo ""
echo "Step 2: Inject drift — adding rogue RDP rule to $SG_ID"
aws ec2 authorize-security-group-ingress \
  --group-id "$SG_ID" \
  --region "ap-south-1" \
  --protocol tcp \
  --port 3389 \
  --cidr 0.0.0.0/0 \
  --no-cli-pager

sleep 5

echo ""
echo "Step 3: Run drift detector — drift should be detected"
if python3 drift-detector/detector.py --env "$ENVIRONMENT"; then
  echo "❌ FAIL: Drift not detected"
else
  echo "🚨 PASS: Drift detected! Alert sent to Slack and Prometheus."
fi

echo ""
echo "=========================================================="
read -p "⏸️  PAUSED FOR VIDEO: Show Slack, Grafana, and trigger Jenkins. Press [Enter] when Jenkins finishes..."
echo "=========================================================="

echo ""
echo "Step 4: Verify drift resolved (Post-Remediation)"
rm -f /tmp/drift_alert_state.json
python3 drift-detector/detector.py --env "$ENVIRONMENT" && echo "✅ PASS: Drift resolved" || echo "❌ FAIL: Drift persists"

echo ""
echo "=== End-to-End Test Complete ==="
