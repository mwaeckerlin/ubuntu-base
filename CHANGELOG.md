# Changelog

- 2026-07-28 **1.0.2**
    - Builds again on the current Ubuntu release (26.04): the newer package manager refuses a removal set whose dependents stay installed, so the minimization list now names all dependents (systemd-sysv, libpam-systemd, polkitd, dbus, …); base-passwd stays because the package manager itself requires it
        - the image gets even slimmer: dbus, polkit, PackageKit and the python stack are removed as well (about 131 MB freed)
    - Test suite added: config contract (apt works, full repository set, runtime user, locale, lean apt defaults, prompt — plus negative checks that systemd and dbus are really gone) and an end to end test that builds a child image through the ONBUILD hooks and verifies packages, configuration commands and the unprivileged user
    - Feature and test registers added (FEATURES.md, TESTS.md) with an automatic guard: every feature must have a test, and no test may be skipped

- 2026-07-17 **1.0.1**
    - Fixed the build cleanup: the post-install cleanup (remove build helpers, clear the apt cache and temporary files) never actually ran because it referenced an undefined variable — deployed sandbox images kept the full apt cache and left-over temporary files. The same broken reference in the derived sandbox images (hermes, openclaw) is fixed by this change too.
    - README now states the role explicitly: this is a deployed runtime / sandbox base that deliberately ships a shell and package manager, unlike the minimal scratch-based runtime images
    - Documented the build-time security trade-off of the `PACKAGES` and `CONFIGURATION_COMMANDS` build arguments
    - Fixed typos in README and Dockerfile comments
