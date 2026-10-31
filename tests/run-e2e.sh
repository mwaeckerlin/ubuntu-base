#!/usr/bin/env bash
# Run the ubuntu-base e2e suite: build a child image through the ONBUILD
# hooks of this branch and verify the contract a derived image relies on.
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

OUT=$(docker compose -f "$COMPOSE" run --rm child 2>&1)
if [[ "${OUT}" == *"start.sh of the child runs"* ]]; then
    _pass "start_sh_is_command"
else
    _fail "start_sh_is_command" "the child did not run its start.sh: '${OUT}'"
fi

if [[ "${OUT}" == *"LANG=C.UTF-8"* ]]; then
    _pass "lang_argument_sets_language"
else
    _fail "lang_argument_sets_language" "build argument lang=C.UTF-8 did not reach LANG: '${OUT}'"
fi

if docker compose -f "$COMPOSE" run --rm --entrypoint curl child --version > /dev/null 2>&1; then
    _pass "pkg_install_installs"
else
    _fail "pkg_install_installs" "curl, installed with \$PKG_INSTALL, is missing"
fi

echo ""
echo "==> E2E results: ${PASS} passed, ${FAIL} failed"
if [[ ${FAIL} -gt 0 ]]; then
    echo "==> Failed: ${FAILED_NAMES[*]}"
    exit 1
fi
