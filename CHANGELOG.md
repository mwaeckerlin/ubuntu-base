# Changelog

- 2026-07-17 **1.0.1**
    - Fixed the build cleanup: the post-install cleanup (remove build helpers, clear the apt cache and temporary files) never actually ran because it referenced an undefined variable — deployed sandbox images kept the full apt cache and left-over temporary files. The same broken reference in the derived sandbox images (hermes, openclaw) is fixed by this change too.
    - README now states the role explicitly: this is a deployed runtime / sandbox base that deliberately ships a shell and package manager, unlike the minimal scratch-based runtime images
    - Documented the build-time security trade-off of the `PACKAGES` and `CONFIGURATION_COMMANDS` build arguments
    - Fixed typos in README and Dockerfile comments
