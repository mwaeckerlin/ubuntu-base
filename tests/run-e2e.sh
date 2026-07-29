#!/usr/bin/env bash
# Run the ubuntu-base e2e suite: build a child image through the ONBUILD
# hooks and verify the full contract a derived image relies on.
# Usage: bash tests/run-e2e.sh
set -uo pipefail

COMPOSE="tests/e2e/docker-compose.yml"
cd "$(dirname "$0")/.."

PASS=0
FAIL=0
declare -a FAILED_NAMES

_pass() { PASS=$((PASS + 1)); echo "  PASS  $1"; }
_fail() { FAIL=$((FAIL + 1)); FAILED_NAMES+=("$1"); echo "  FAIL  $1: $2"; }

cleanup() {
    docker compose -f "$COMPOSE" down -v --remove-orphans --rmi all 2>/dev/null || true
}
trap cleanup EXIT

echo "==> Building child image through the ONBUILD hooks..."
if ! docker compose -f "$COMPOSE" build child; then
    _fail "child_builds" "ONBUILD chain failed — see build output above"
    echo ""
    echo "==> E2E results: ${PASS} passed, ${FAIL} failed"
    exit 1
fi
_pass "child_builds"

if docker compose -f "$COMPOSE" run --rm child curl --version > /dev/null 2>&1; then
    _pass "packages_installed"
else
    _fail "packages_installed" "curl from PACKAGES is not installed"
fi

if docker compose -f "$COMPOSE" run --rm child test -e /etc/e2e-config-marker > /dev/null 2>&1; then
    _pass "configuration_commands_ran"
else
    _fail "configuration_commands_ran" "CONFIGURATION_COMMANDS marker missing"
fi

WHO=$(docker compose -f "$COMPOSE" run --rm child whoami 2>&1)
if [[ "${WHO}" == *"somebody"* ]]; then
    _pass "child_runs_unprivileged"
else
    _fail "child_runs_unprivileged" "child runs as '${WHO}', not somebody"
fi

echo ""
echo "==> E2E results: ${PASS} passed, ${FAIL} failed"
if [[ ${FAIL} -gt 0 ]]; then
    echo "==> Failed: ${FAILED_NAMES[*]}"
    exit 1
fi
