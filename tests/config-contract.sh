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

    # the environment every image built on this one inherits; PS1 ends in a
    # space, so both sides are compared without trailing blanks
    EXPECTED_ENV=$(sed 's/[[:space:]]*$//' <<'EOF' | sort
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
CONTAINERNAME=base
WWWUSER=nginx
WWWGROUP=nginx
SHARED_GROUP_NAME=shared-access
SHARED_GROUP_ID=500
LANG=en_US.UTF-8
RUN_USER=somebody
RUN_GROUP=somebody
RUN_HOME=/home/somebody
PKG_INSTALL=apt-get install --no-install-recommends --no-install-suggests -y
PKG_REMOVE=apt-get autoremove --purge -y
PKG_SEARCH=apt-cache search
ALLOW_USER=chown -R somebody:somebody
PS1=\[\033[36;1m\]\u\[\033[97m\]@\[\033[32m\]${CONTAINERNAME}[\[\033[36m\]\h\[\033[97m\]]:\[\033[37m\]\w\[\033[0m\]\$
PS4=$(printf "\[\033[37;1m\]$0 \[\033[33m\]%4d\[\033[0m\]: " ${LINENO})
TERM=xterm
DEBIAN_FRONTEND=noninteractive
_TMP_PACKAGES=lsb-release wget software-properties-common gpg-agent
_PACKAGES=language-pack-en apt-transport-https
EOF
)
    ACTUAL_ENV=$(docker image inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "${IMAGE}" 2>&1 | sed -e 's/[[:space:]]*$//' -e '/^$/d' | sort)
    if [[ "${ACTUAL_ENV}" == "${EXPECTED_ENV}" ]]; then
        _pass "environment_unchanged"
    else
        _fail "environment_unchanged" "$(diff <(echo "${EXPECTED_ENV}") <(echo "${ACTUAL_ENV}"))"
    fi

    RUNTIME=$(docker image inspect --format '{{json .Config.Cmd}} user={{.Config.User}}' "${IMAGE}" 2>&1)
    if [[ "${RUNTIME}" == '["/bin/bash"] user=' ]]; then
        _pass "command_and_user_unchanged"
    else
        _fail "command_and_user_unchanged" "command and user are: ${RUNTIME}"
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
