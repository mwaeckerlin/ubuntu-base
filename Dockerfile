ARG VERSION="latest"
FROM ubuntu:${VERSION}
MAINTAINER mwaeckerlin
ARG wwwuser="nginx"
ARG wwwgroup="nginx"
ARG lang="en_US.UTF-8"

# change in childern:
ENV CONTAINERNAME     "base"

ENV WWWUSER           "${wwwuser}"
ENV WWWGROUP          "${wwwuser}"
ENV SHARED_GROUP_NAME "shared-access"
ENV SHARED_GROUP_ID   "500"
ENV LANG              "${lang}"
ENV RUN_USER          "somebody"
ENV RUN_GROUP         "somebody"
ENV RUN_HOME          "/home/somebody"

ENV PKG_INSTALL "apt-get install --no-install-recommends --no-install-suggests -y"
ENV PKG_REMOVE  "apt-get autoremove --purge -y"
ENV PKG_SEARCH  "apt-cache search"
ENV ALLOW_USER  "chown -R ${RUN_USER}:${RUN_GROUP}"

ENV PS1               '\[\033[36;1m\]\u\[\033[97m\]@\[\033[32m\]${CONTAINERNAME}[\[\033[36m\]\h\[\033[97m\]]:\[\033[37m\]\w\[\033[0m\]\$ '

ENV PS4               '$(printf "\[\033[37;1m\]$0 \[\033[33m\]%4d\[\033[0m\]: " ${LINENO})'
ENV TERM              "xterm"
ENV DEBIAN_FRONTEND   "noninteractive"

ENV _TMP_PACKAGES     "lsb-release wget software-properties-common gpg-agent"
#ENV _REMOVE_PACKAGES  "systemd base-passwd e2fslibs e2fsprogs initscripts libapparmor1 libsystemd0 bsdutils util-linux libudev1 makedev mount sysv-rc sysvinit-utils apt+ libudev1+"
ENV _PACKAGES         "language-pack-en apt-transport-https"

ADD cleanup.sh /cleanup.sh
ADD aptconf /etc/apt/apt.conf.d/aptconf
ADD bash.bashrc /etc/bash.bashrc
ADD profile /etc/profile
RUN groupadd -g ${SHARED_GROUP_ID} ${SHARED_GROUP_NAME} \
 && rm -r /root/.bashrc /root/.profile /etc/skel \
 && apt-get update \
 && apt-get dist-upgrade -y \
 && $PKG_INSTALL $_PACKAGES $_TMP_PACKAGES  \
 && apt-get update \
 && locale-gen ${LANG} \
 && update-locale LANG=${LANG} \
 && $PKG_REMOVE $_TMP_PACKAGES $_REMOVE_PACKAGES \
 && /cleanup.sh

## update when used in derieved images
#ONBUILD RUN apt-get update && apt-get dist-upgrade -y

# derieved images must have a /start.sh command as entrypoint
ONBUILD ADD start.sh /start.sh
ONBUILD CMD ["/start.sh"]

## derieved images must have a health check script at /health.sh
##ONBUILD ADD health.sh /health.sh
##ONBUILD HEALTHCHECK --interval=120s --timeout=30s --start-period=600s --retries=3 CMD /health.sh

# allow derieved images to overwrite the language
ONBUILD ARG lang
ONBUILD ENV LANG=${lang:-${LANG}}
