ARG VERSION="latest"
FROM ubuntu:${VERSION} AS build
ARG wwwuser="nginx"
ARG wwwgroup="nginx"
ARG lang="en_US.UTF-8"

# change in children:
ENV CONTAINERNAME     "base"

ENV WWWUSER          "${wwwuser}"
ENV WWWGROUP         "${wwwgroup}"
ENV LANG             "${lang}"
ENV RUN_USER         "somebody"
ENV RUN_GROUP        "${RUN_USER}"
ENV RUN_HOME         "/home/${RUN_USER}"

ENV PKG_INSTALL      "apt-get install --no-install-recommends --no-install-suggests -y"
ENV PKG_REMOVE       "apt-get autoremove --purge -y --allow-remove-essential"
ENV PKG_SEARCH       "apt-cache search"
ENV PKG_CLEANUP      "${PKG_REMOVE} && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*"
ENV ALLOW_USER       "chown -R ${RUN_USER}:${RUN_GROUP}"

ENV PS1              '\[\033[36;1m\]\u\[\033[97m\]@\[\033[32m\]${CONTAINERNAME}[\[\033[36m\]\h\[\033[97m\]]:\[\033[37m\]\w\[\033[0m\]\$ '

ENV PS4              '$(printf "\[\033[37;1m\]$0 \[\033[33m\]%4d\[\033[0m\]: " ${LINENO})'
ENV TERM             "xterm"
ENV DEBIAN_FRONTEND  "noninteractive"

ENV _TMP_PACKAGES    "lsb-release wget software-properties-common gpg-agent"
# apt >= 3 (Ubuntu 26.04) refuses a removal set whose reverse dependencies
# stay installed, so every dependent must be listed too (systemd-sysv,
# libpam-systemd, polkitd, dbus, python3-distro, ...); base-passwd must
# STAY — apt itself depends on it. The trailing "apt+ libudev1+" pin both
# as installed.
ENV _REMOVE_PACKAGES "login logsave systemd systemd-sysv libpam-systemd polkitd dbus dbus-daemon dbus-system-bus-common python3-distro python3-software-properties e2fslibs e2fsprogs initscripts libapparmor1 unminimize bsdutils util-linux makedev mount sysvinit-utils apt+ libudev1+"
ENV _PACKAGES        "language-pack-en apt-transport-https software-properties-common"

ADD aptconf /etc/apt/apt.conf.d/aptconf
ADD bash.bashrc /etc/bash.bashrc
ADD profile /etc/profile
RUN rm -r /root/.bashrc /root/.profile /etc/skel
RUN apt-get update
RUN apt-get dist-upgrade -y
RUN $PKG_INSTALL $_PACKAGES $_TMP_PACKAGES 
RUN apt-add-repository main restricted universe multiverse
RUN apt-get update
RUN locale-gen ${LANG}
RUN update-locale LANG=${LANG}
RUN $PKG_REMOVE $_TMP_PACKAGES $_REMOVE_PACKAGES
RUN bash -c "$PKG_CLEANUP"
RUN userdel -r ubuntu 2>/dev/null; groupdel ubuntu 2>/dev/null; true
RUN groupadd ${RUN_GROUP}
RUN useradd -m -d ${RUN_HOME} -s /bin/bash -g ${RUN_GROUP} ${RUN_USER}

FROM build
ONBUILD ARG PACKAGES
ONBUILD ARG CONFIGURATION_COMMANDS
ONBUILD RUN apt-get update && apt-get dist-upgrade -y && $PKG_INSTALL ${PACKAGES}
ONBUILD ARG lang
ONBUILD ENV LANG=${lang:-${LANG}}
ONBUILD RUN bash -c "${CONFIGURATION_COMMANDS}"
ONBUILD USER ${RUN_USER}
WORKDIR ${RUN_HOME}
