# E2E child image: proves the ONBUILD contract of mwaeckerlin/ubuntu-base on
# this branch — start.sh of the child is added and is its command, the build
# argument lang sets LANG, and $PKG_INSTALL installs a package.
ARG VERSION="noble"
FROM mwaeckerlin/ubuntu-base:${VERSION}
RUN apt-get update && $PKG_INSTALL curl
