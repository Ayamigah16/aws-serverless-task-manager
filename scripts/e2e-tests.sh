#!/bin/bash
# End-to-End Testing Script

set -e

API_URL="${API_URL:-}"
ADMIN_TOKEN="${ADMIN_TOKEN:-}"
MEMBER_TOKEN="${MEMBER_TOKEN:-}"

if [ -z "$API_URL" ] || [ -z "$ADMIN_TOKEN" ] || [ -z "$MEMBER_TOKEN" ]; then
  echo "Usage: API_URL=<url> ADMIN_TOKEN=<token> MEMBER_TOKEN=<token> ./e2e-tests.sh"
  exit 1
fi

PASS=0
FAIL=0

test_result() {
  if [ $1 -eq 0 ]; then
    echo "✓ PASS: $2"
    ((PASS++))
  else
    echo "✗ FAIL: $2"
    ((FAIL++))
  fi
}

echo "=== E2E Testing ==="
echo ""

# Test 1: Admin creates task
echo "Test 1: Admin creates task"
RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"E2E Test Task","description":"Testing","priority":"HIGH"}')
TASK_ID=$(echo $RESPONSE | jq -r '.taskId // .TaskId // empty')
if [ -n "$TASK_ID" ]; then
  test_result 0 "Admin created task: $TASK_ID"
else
  test_result 1 "Admin failed to create task"
fi
echo ""

# Test 2: Member cannot create task
echo "Test 2: Member cannot create task"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_URL" \
  -H "Authorization: Bearer $MEMBER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Should Fail","priority":"HIGH"}')
[ "$HTTP_CODE" = "403" ]
test_result $? "Member blocked from creating task (403)"
echo ""

# Test 3: Admin lists all tasks
echo "Test 3: Admin lists all tasks"
RESPONSE=$(curl -s -X GET "$API_URL" \
  -H "Authorization: Bearer $ADMIN_TOKEN")
COUNT=$(echo $RESPONSE | jq -r '.count // 0')
[ "$COUNT" -gt 0 ]
test_result $? "Admin can list tasks (count: $COUNT)"
echo ""

# Test 4: Admin assigns task
if [ -n "$TASK_ID" ]; then
  echo "Test 4: Admin assigns task"
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_URL/$TASK_ID/assign" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"assignedTo":"member-user-id"}')
  [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]
  test_result $? "Admin assigned task"
  echo ""
fi

# Test 5: Member updates task status
if [ -n "$TASK_ID" ]; then
  echo "Test 5: Member updates task status"
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$API_URL/$TASK_ID/status" \
    -H "Authorization: Bearer $MEMBER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"status":"IN_PROGRESS"}')
  [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "403" ]
  test_result $? "Member updated status or was blocked (expected)"
  echo ""
fi

# Test 6: Admin closes task
if [ -n "$TASK_ID" ]; then
  echo "Test 6: Admin closes task"
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_URL/$TASK_ID/close" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
  [ "$HTTP_CODE" = "200" ]
  test_result $? "Admin closed task"
  echo ""
fi

# Test 7: Member cannot close task
if [ -n "$TASK_ID" ]; then
  echo "Test 7: Member cannot close task"
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_URL/$TASK_ID/close" \
    -H "Authorization: Bearer $MEMBER_TOKEN")
  [ "$HTTP_CODE" = "403" ]
  test_result $? "Member blocked from closing task"
  echo ""
fi

echo "=== Test Summary ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
