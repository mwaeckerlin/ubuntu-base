#!/usr/bin/env bash
# Workflow contract: the Dockerfile, the compose file and the GitHub workflow
# of this branch name the same Ubuntu release, and the workflow builds and
# publishes it for every architecture of the shared workflow.
#
# Usage: tests/workflow-contract.sh RELEASE

set -uo pipefail
cd "$(dirname "$0")/.."

RELEASE="${1:?usage: tests/workflow-contract.sh RELEASE}"
WORKFLOW=".github/workflows/docker.yml"

PASS=0
FAIL=0
declare -a FAILED_NAMES

_pass() { PASS=$((PASS + 1)); echo "  PASS  $1"; }
_fail() { FAIL=$((FAIL + 1)); FAILED_NAMES+=("$1"); echo "  FAIL  $1: $2"; }

echo "==> Workflow contract: Ubuntu ${RELEASE}"

if grep -qx "ARG VERSION=\"${RELEASE}\"" Dockerfile; then
    _pass "dockerfile_release"
else
    _fail "dockerfile_release" "Dockerfile does not build FROM ubuntu:${RELEASE}"
fi

if grep -qE "^ +image: mwaeckerlin/ubuntu-base:${RELEASE}$" docker-compose.yml; then
    _pass "compose_tag"
else
    _fail "compose_tag" "docker-compose.yml does not publish mwaeckerlin/ubuntu-base:${RELEASE}"
fi

if grep -qE "^ +branches: \[master, jammy, noble\]$" "${WORKFLOW}"; then
    _pass "workflow_push_branches"
else
    _fail "workflow_push_branches" "a push to ${RELEASE} does not start ${WORKFLOW}"
fi

if grep -qF '"branch": "jammy|noble", "suffix": "", "version": "v"' "${WORKFLOW}"; then
    _pass "workflow_branch_rule"
else
    _fail "workflow_branch_rule" "no branch-tags rule names ${RELEASE} with the version prefix v"
fi

if grep -qE 'uses: mwaeckerlin/scratch/\.github/workflows/docker-image\.yml@master' "${WORKFLOW}"; then
    _pass "workflow_shared_build"
else
    _fail "workflow_shared_build" "${WORKFLOW} does not call the shared workflow of mwaeckerlin/scratch"
fi

# the shared workflow builds amd64 and arm64 unless a caller narrows the list
if grep -q 'architectures:' "${WORKFLOW}"; then
    _fail "workflow_all_architectures" "${WORKFLOW} narrows the architectures"
else
    _pass "workflow_all_architectures"
fi

echo ""
echo "==> Workflow contract results: ${PASS} passed, ${FAIL} failed"
if [[ ${FAIL} -gt 0 ]]; then
    echo "==> Failed contracts: ${FAILED_NAMES[*]}"
    exit 1
fi
