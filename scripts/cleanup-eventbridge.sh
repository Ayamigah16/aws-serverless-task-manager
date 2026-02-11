#!/bin/bash

set -e

echo "🧹 Cleaning up EventBridge targets..."

BUS_NAME="task-manager-sandbox-events"
RULES=("task-manager-sandbox-events-task-assigned" "task-manager-sandbox-events-task-closed" "task-manager-sandbox-events-task-status-updated")

for RULE in "${RULES[@]}"; do
  echo "Removing targets from rule: $RULE"
  
  # List targets
  TARGETS=$(aws events list-targets-by-rule --rule "$RULE" --event-bus-name "$BUS_NAME" --query 'Targets[].Id' --output text 2>/dev/null || echo "")
  
  if [ -n "$TARGETS" ]; then
    # Remove targets
    for TARGET_ID in $TARGETS; do
      echo "  Removing target: $TARGET_ID"
      aws events remove-targets --rule "$RULE" --event-bus-name "$BUS_NAME" --ids "$TARGET_ID" --no-cli-pager 2>/dev/null || true
    done
  else
    echo "  No targets found"
  fi
done

echo "✅ EventBridge cleanup complete"
echo ""
echo "Now run: terraform destroy -auto-approve"
