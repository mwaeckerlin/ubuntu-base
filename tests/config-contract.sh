#!/usr/bin/env bash
# Config contract: the image carries the Ubuntu release of its branch with
# every package upgraded, a working apt, the locale and the lean apt
# defaults, and it keeps the ONBUILD contract the images built on it rely on
# (`ADD start.sh /start.sh`, `CMD ["/start.sh"]`). `--pull=never` keeps
# docker from silently pulling a published image when the local build is
# missing.
#
# Usage: tests/config-contract.sh IMAGE RELEASE

set -uo pipefail

IMAGE="${1:?usage: tests/config-contract.sh IMAGE RELEASE}"
RELEASE="${2:?usage: tests/config-contract.sh IMAGE RELEASE}"

PASS=0
FAIL=0
declare -a FAILED_NAMES

_pass() { PASS=$((PASS + 1)); echo "  PASS  $1"; }
_fail() { FAIL=$((FAIL + 1)); FAILED_NAMES+=("$1"); echo "  FAIL  $1: $2"; }

run() { docker run --rm --pull=never --entrypoint /bin/sh "${IMAGE}" -c "$1"; }

echo "==> Config contract: Ubuntu ${RELEASE} base with the start.sh contract"

if ! docker image inspect "${IMAGE}" > /dev/null 2>&1; then
    _fail "image_exists" "image not built — run 'npm run build' first"
else
    CODENAME=$(run '. /etc/os-release && echo "$VERSION_CODENAME"' 2>&1)
    if [[ "${CODENAME}" == "${RELEASE}" ]]; then
        _pass "release_${RELEASE}"
    else
        _fail "release_${RELEASE}" "the image carries '${CODENAME}'"
    fi

    if run 'apt-get --version' > /dev/null 2>&1; then
        _pass "apt_works"
    else
        _fail "apt_works" "apt-get missing or broken after the cleanup"
    fi

    # the build runs dist-upgrade, so right after it nothing is left to
    # upgrade; this is what brings the security fixes of Ubuntu into the image
    UPGRADE=$(run 'apt-get update -qq > /dev/null && apt-get -s dist-upgrade' 2>&1)
    if echo "${UPGRADE}" | grep -qE '^0 upgraded, 0 newly installed'; then
        _pass "packages_current"
    else
        _fail "packages_current" "packages are left to upgrade: $(echo "${UPGRADE}" | grep -E '^(Inst|[0-9]+ upgraded)' | head -n 5)"
    fi

    # negative: the packages the build only needs while it runs are gone
    if run '! command -v wget && ! dpkg -s software-properties-common > /dev/null 2>&1' > /dev/null 2>&1; then
        _pass "build_packages_removed"
    else
        _fail "build_packages_removed" "wget or software-properties-common is still installed"
    fi

    if run 'test -e /usr/lib/locale/locale-archive' > /dev/null 2>&1; then
        _pass "locale_generated"
    else
        _fail "locale_generated" "locale archive missing — locale-gen did not run"
    fi

    APTCONF=$(docker run --rm --pull=never --entrypoint /usr/bin/apt-config "${IMAGE}" dump 2>&1)
    if echo "${APTCONF}" | grep -q 'APT::Get::Install-Recommends "false"'; then
        _pass "no_recommends"
    else
        _fail "no_recommends" "apt still installs recommends"
    fi

    GROUP=$(run 'getent group shared-access' 2>&1)
    if [[ "${GROUP}" == "shared-access:x:500:"* ]]; then
        _pass "shared_group"
    else
        _fail "shared_group" "group shared-access with gid 500 missing: '${GROUP}'"
    fi

    ENV_OUT=$(docker image inspect --format '{{.Config.Env}}' "${IMAGE}" 2>&1)
    if echo "${ENV_OUT}" | grep -q 'PS1=' && echo "${ENV_OUT}" | grep -q 'LANG=en_US.UTF-8'; then
        _pass "prompt_and_language_env"
    else
        _fail "prompt_and_language_env" "PS1 or LANG=en_US.UTF-8 not preconfigured"
    fi

    ONBUILD=$(docker image inspect --format '{{range .Config.OnBuild}}{{println .}}{{end}}' "${IMAGE}" 2>&1)
    if echo "${ONBUILD}" | grep -qxF 'ADD start.sh /start.sh' && echo "${ONBUILD}" | grep -qxF 'CMD ["/start.sh"]'; then
        _pass "onbuild_start_contract"
    else
        _fail "onbuild_start_contract" "ONBUILD instructions are: ${ONBUILD}"
    fi
fi

echo ""
echo "==> Config contract results: ${PASS} passed, ${FAIL} failed"
if [[ ${FAIL} -gt 0 ]]; then
    echo "==> Failed contracts: ${FAILED_NAMES[*]}"
    exit 1
fi
