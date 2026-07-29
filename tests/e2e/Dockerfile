# E2E child image: proves the ONBUILD contract of mwaeckerlin/ubuntu-base —
# PACKAGES are installed, CONFIGURATION_COMMANDS run as root during the
# build, and the resulting image runs as the unprivileged user.
ARG PACKAGES="curl"
ARG CONFIGURATION_COMMANDS="touch /etc/e2e-config-marker"
FROM mwaeckerlin/ubuntu-base
