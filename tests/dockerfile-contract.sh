#!/usr/bin/env bash
# Dockerfile contract: the build of the image emits no warning.
#
# `docker build --check` runs the build checks of BuildKit without building;
# the Dockerfile in the legacy form `ENV key value` with `MAINTAINER` warned
# on every build. A build without the cache then shows that no step of it
# warns about a missing locale.
#
# Usage: tests/dockerfile-contract.sh

set -uo pipefail
cd "$(dirname "$0")/.."

PASS=0
FAIL=0
declare -a FAILED_NAMES

_pass() { PASS=$((PASS + 1)); echo "  PASS  $1"; }
_fail() { FAIL=$((FAIL + 1)); FAILED_NAMES+=("$1"); echo "  FAIL  $1: $2"; }

echo "==> Dockerfile contract: no build warnings"

OUT=$(docker build --check . 2>&1)
RC=$?
if [[ ${RC} -eq 0 && "${OUT}" == *"no warnings found"* ]]; then
    _pass "build_without_warnings"
else
    _fail "build_without_warnings" "${OUT}"
fi

# the package scripts of the build print a perl warning for every step that
# runs with a LANG whose locale is not generated yet; only a build without
# the cache runs them, and the cache-only output keeps no image behind
BUILD=$(docker build --no-cache --progress=plain --output type=cacheonly . 2>&1)
RC=$?
LOCALE=$(echo "${BUILD}" | grep -E 'Setting locale failed|Cannot set LC_|Falling back to the standard locale')
if [[ ${RC} -ne 0 ]]; then
    _fail "build_without_locale_warnings" "the build failed: $(echo "${BUILD}" | tail -n 20)"
elif [[ -n "${LOCALE}" ]]; then
    _fail "build_without_locale_warnings" "${LOCALE}"
else
    _pass "build_without_locale_warnings"
fi

echo ""
echo "==> Dockerfile contract results: ${PASS} passed, ${FAIL} failed"
if [[ ${FAIL} -gt 0 ]]; then
    echo "==> Failed contracts: ${FAILED_NAMES[*]}"
    exit 1
fi
