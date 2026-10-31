#!/usr/bin/env bash
# Workflow contract: the GitHub workflow of master publishes the image for
# every architecture of the shared workflow, and its hourly run starts the
# workflow on the release branches jammy and noble and on no other branch.
#
# The branch selection is the one of the job `branches` of the shared
# workflow of mwaeckerlin/scratch: every branch except the running one that a
# rule of `branch-tags` matches in full. The same rules give master its tags,
# so no rule may match master.
#
# Usage: tests/workflow-contract.sh

set -uo pipefail
cd "$(dirname "$0")/.."

WORKFLOW=".github/workflows/docker.yml"

PASS=0
FAIL=0
declare -a FAILED_NAMES

_pass() { PASS=$((PASS + 1)); echo "  PASS  $1"; }
_fail() { FAIL=$((FAIL + 1)); FAILED_NAMES+=("$1"); echo "  FAIL  $1: $2"; }

echo "==> Workflow contract: master and the release branches"

if grep -qE 'uses: mwaeckerlin/scratch/\.github/workflows/docker-image\.yml@master' "${WORKFLOW}"; then
    _pass "shared_build"
else
    _fail "shared_build" "${WORKFLOW} does not call the shared workflow of mwaeckerlin/scratch"
fi

# the shared workflow builds amd64 and arm64 unless a caller narrows the list
if grep -q 'architectures:' "${WORKFLOW}"; then
    _fail "all_architectures" "${WORKFLOW} narrows the architectures"
else
    _pass "all_architectures"
fi

if grep -qE '^ +branches: \[master, jammy, noble\]$' "${WORKFLOW}"; then
    _pass "push_branches"
else
    _fail "push_branches" "a push to master, jammy or noble does not start ${WORKFLOW}"
fi

if grep -qE '^ +- cron: ' "${WORKFLOW}" && grep -qE '^ +actions: write$' "${WORKFLOW}"; then
    _pass "hourly_run_may_start_branches"
else
    _fail "hourly_run_may_start_branches" "${WORKFLOW} has no schedule or does not grant actions: write"
fi

RULES=$(grep -oE "branch-tags: '.*'" "${WORKFLOW}" | sed -E "s/^branch-tags: '(.*)'$/\1/")
STARTED=$(RULES="${RULES}" python3 - <<'EOF'
import json, os, re
rules = json.loads(os.environ['RULES'] or '[]')
branches = ['master', 'jammy', 'noble', 'latest']
print(' '.join(b for b in branches
               if b != 'master' and any('branch' in r and re.fullmatch(r['branch'], b) for r in rules)))
EOF
)
if [[ "${STARTED}" == "jammy noble" ]]; then
    _pass "hourly_run_starts_jammy_and_noble"
else
    _fail "hourly_run_starts_jammy_and_noble" "the hourly run of master starts '${STARTED}'"
fi

MASTER=$(RULES="${RULES}" python3 - <<'EOF'
import json, os, re
rules = json.loads(os.environ['RULES'] or '[]')
print(any('branch' in r and re.fullmatch(r['branch'], 'master') for r in rules))
EOF
)
if [[ "${MASTER}" == "False" ]]; then
    _pass "master_tags_unchanged"
else
    _fail "master_tags_unchanged" "a rule of branch-tags matches master and changes its tags"
fi

echo ""
echo "==> Workflow contract results: ${PASS} passed, ${FAIL} failed"
if [[ ${FAIL} -gt 0 ]]; then
    echo "==> Failed contracts: ${FAILED_NAMES[*]}"
    exit 1
fi
