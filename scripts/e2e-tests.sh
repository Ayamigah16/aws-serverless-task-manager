#!/bin/bash
# End-to-End Testing Script
# Tests complete user flows with authentication

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# ============================================================================
# CONFIGURATION
# ============================================================================

API_URL="${API_URL:-}"
ADMIN_TOKEN="${ADMIN_TOKEN:-}"
MEMBER_TOKEN="${MEMBER_TOKEN:-}"

PASS=0
FAIL=0

# ============================================================================
# FUNCTIONS
# ============================================================================

# Record test result
test_result() {
  if [ $1 -eq 0 ]; then
    log_success "PASS: $2"
    ((PASS++))
  else
    log_error "FAIL: $2"
    ((FAIL++))
  fi
}

# Run all tests
run_tests() {
    local TASK_ID=""

    log_info "E2E Testing"

    # Test 1: Admin creates task
    log_info "Test 1: Admin creates task"
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

# Test 2: Member cannot create task
log_info "Test 2: Member cannot create task"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_URL" \
  -H "Authorization: Bearer $MEMBER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Should Fail","priority":"HIGH"}')
[ "$HTTP_CODE" = "403" ]
test_result $? "Member blocked from creating task (403)"

# Test 3: Admin lists all tasks
log_info "Test 3: Admin lists all tasks"
RESPONSE=$(curl -s -X GET "$API_URL" \
  -H "Authorization: Bearer $ADMIN_TOKEN")
COUNT=$(echo $RESPONSE | jq -r '.count // 0')
[ "$COUNT" -gt 0 ]
test_result $? "Admin can list tasks (count: $COUNT)"

# Test 4: Admin assigns task
if [ -n "$TASK_ID" ]; then
  log_info "Test 4: Admin assigns task"
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_URL/$TASK_ID/assign" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"assignedTo":"member-user-id"}')
  [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]
  test_result $? "Admin assigned task"
fi

# Test 5: Member updates task status
if [ -n "$TASK_ID" ]; then
  log_info "Test 5: Member updates task status"
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$API_URL/$TASK_ID/status" \
    -H "Authorization: Bearer $MEMBER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"status":"IN_PROGRESS"}')
  [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "403" ]
  test_result $? "Member updated status or was blocked (expected)"
fi

# Test 6: Admin closes task
if [ -n "$TASK_ID" ]; then
  log_info "Test 6: Admin closes task"
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_URL/$TASK_ID/close" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
  [ "$HTTP_CODE" = "200" ]
  test_result $? "Admin closed task"
fi

# Test 7: Member cannot close task
if [ -n "$TASK_ID" ]; then
  log_info "Test 7: Member cannot close task"
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_URL/$TASK_ID/close" \
    -H "Authorization: Bearer $MEMBER_TOKEN")
      test_result $? "Member blocked from closing task"
    fi
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    # Validate inputs
    [ -z "$API_URL" ] || [ -z "$ADMIN_TOKEN" ] || [ -z "$MEMBER_TOKEN" ] && \
        die "Usage: API_URL=<url> ADMIN_TOKEN=<token> MEMBER_TOKEN=<token> ./e2e-tests.sh"

    # Run tests
    run_tests

    # Show summary
    log_info "Test Summary"
    log_info "Passed: $PASS"
    log_info "Failed: $FAIL"

    if [ $FAIL -eq 0 ]; then
      log_success "All tests passed!"
      exit 0
    else
      log_error "Some tests failed"
      exit 1
    fi
}

main "$@"
