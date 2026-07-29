#!/usr/bin/env bash
# Config contract: the shipped sandbox base must be minimal but functional.
#
# The image deliberately ships a shell and apt (sandbox role, see README),
# but the init/desktop infrastructure (systemd, dbus, polkit) must be gone,
# apt must keep working for derived images, and the runtime user, locale
# and lean apt defaults must be in place. `--pull=never` keeps docker from
# silently pulling a stale image when the local build is missing.
#
# Usage: tests/config-contract.sh IMAGE

set -uo pipefail

IMAGE="${1:?usage: tests/config-contract.sh IMAGE}"

PASS=0
FAIL=0
declare -a FAILED_NAMES

_pass() { PASS=$((PASS + 1)); echo "  PASS  $1"; }
_fail() { FAIL=$((FAIL + 1)); FAILED_NAMES+=("$1"); echo "  FAIL  $1: $2"; }

echo "==> Config contract: minimal but functional ubuntu sandbox base"

if ! docker image inspect "${IMAGE}" > /dev/null 2>&1; then
    _fail "${IMAGE}_image_exists" "image not built — run 'npm run build' first"
else
    if docker run --rm --pull=never --entrypoint /usr/bin/apt-get "${IMAGE}" --version > /dev/null 2>&1; then
        _pass "${IMAGE}_apt_works"
    else
        _fail "${IMAGE}_apt_works" "apt-get missing or broken after minimization"
    fi

    if docker run --rm --pull=never --entrypoint /bin/sh "${IMAGE}" -c 'grep -rq multiverse /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null' > /dev/null 2>&1; then
        _pass "${IMAGE}_full_repo_set"
    else
        _fail "${IMAGE}_full_repo_set" "multiverse component not enabled"
    fi

    # negative: the init/desktop infrastructure must NOT be shipped
    if docker run --rm --pull=never --entrypoint /bin/sh "${IMAGE}" -c 'test ! -e /usr/lib/systemd/systemd && test ! -e /usr/bin/systemctl && test ! -e /bin/systemctl' > /dev/null 2>&1; then
        _pass "${IMAGE}_no_systemd"
    else
        _fail "${IMAGE}_no_systemd" "systemd still present"
    fi
    if docker run --rm --pull=never --entrypoint /bin/sh "${IMAGE}" -c '! command -v dbus-daemon' > /dev/null 2>&1; then
        _pass "${IMAGE}_no_dbus"
    else
        _fail "${IMAGE}_no_dbus" "dbus still present"
    fi

    UID_OUT=$(docker run --rm --pull=never --entrypoint /usr/bin/id "${IMAGE}" -u somebody 2>&1)
    if [[ "${UID_OUT}" == "1000" ]]; then
        _pass "${IMAGE}_runtime_user"
    else
        _fail "${IMAGE}_runtime_user" "user somebody missing or uid != 1000: '${UID_OUT}'"
    fi

    if docker run --rm --pull=never --entrypoint /bin/sh "${IMAGE}" -c 'test -e /usr/lib/locale/locale-archive' > /dev/null 2>&1; then
        _pass "${IMAGE}_locale_generated"
    else
        _fail "${IMAGE}_locale_generated" "locale archive missing — locale-gen did not run"
    fi

    APTCONF=$(docker run --rm --pull=never --entrypoint /usr/bin/apt-config "${IMAGE}" dump 2>&1)
    if echo "${APTCONF}" | grep -q 'APT::Get::Install-Recommends "false"'; then
        _pass "${IMAGE}_no_recommends"
    else
        _fail "${IMAGE}_no_recommends" "apt still installs recommends"
    fi

    ENV_OUT=$(docker image inspect --format '{{.Config.Env}}' "${IMAGE}" 2>&1)
    if echo "${ENV_OUT}" | grep -q 'PS1='; then
        _pass "${IMAGE}_prompt_env"
    else
        _fail "${IMAGE}_prompt_env" "PS1 prompt not preconfigured"
    fi
fi

echo ""
echo "==> Config contract results: ${PASS} passed, ${FAIL} failed"
if [[ ${FAIL} -gt 0 ]]; then
    echo "==> Failed contracts: ${FAILED_NAMES[*]}"
    exit 1
fi
