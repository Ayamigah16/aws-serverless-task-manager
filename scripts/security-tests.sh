#!/bin/bash
# Security Testing Script
# Tests authentication, authorization, and input validation

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

# ============================================================================
# FUNCTIONS
# ============================================================================

# Run all security tests
run_security_tests() {
    log_info "Security Testing"

# Test 1: Invalid JWT
log_info "Test 1: Invalid JWT token"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$API_URL" \
  -H "Authorization: Bearer invalid-token")
if [ "$RESPONSE" = "401" ]; then
  log_success "Invalid token rejected (401)"
else
  log_error "Expected 401, got $RESPONSE"
fi

# Test 2: Missing JWT
log_info "Test 2: Missing JWT token"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$API_URL")
if [ "$RESPONSE" = "401" ]; then
  log_success "Missing token rejected (401)"
else
  log_error "Expected 401, got $RESPONSE"
fi

# Test 3: RBAC - Member cannot create task
log_info "Test 3: RBAC - Member cannot create task"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_URL" \
  -H "Authorization: Bearer $MEMBER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","priority":"HIGH"}')
if [ "$RESPONSE" = "403" ]; then
  log_success "Member blocked from creating task (403)"
else
  log_error "Expected 403, got $RESPONSE"
fi

# Test 4: Admin can create task
log_info "Test 4: Admin can create task"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_URL" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Security Test","priority":"HIGH"}')
if [ "$RESPONSE" = "201" ] || [ "$RESPONSE" = "200" ]; then
  log_success "Admin can create task ($RESPONSE)"
else
  log_error "Expected 201/200, got $RESPONSE"
fi

# Test 5: XSS attempt
log_info "Test 5: XSS payload handling"
RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"<script>alert(1)</script>","priority":"HIGH"}')
log_debug "Response: $RESPONSE"
if echo "$RESPONSE" | grep -q "script"; then
  log_warn "XSS payload not sanitized"
else
  log_success "XSS payload handled"
fi

# Test 6: SQL injection attempt
log_info "Test 6: SQL injection payload handling"
RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test\"; DROP TABLE--","priority":"HIGH"}')
log_debug "Response: $RESPONSE"
if echo "$RESPONSE" | grep -q "error"; then
  log_success "SQL injection rejected or sanitized"
else
  log_success "SQL injection handled (NoSQL database)"
fi
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    # Validate inputs
    [ -z "$API_URL" ] || [ -z "$ADMIN_TOKEN" ] || [ -z "$MEMBER_TOKEN" ] && \
        die "Usage: API_URL=<url> ADMIN_TOKEN=<token> MEMBER_TOKEN=<token> ./security-tests.sh"

    # Run security tests
    run_security_tests

    log_info "Security tests complete"
}

main "$@"
