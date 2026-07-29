# Tests

Register of all tests, grouped by kind and sorted by the
[FEATURES.md](FEATURES.md) number each test covers. `npm test` runs
everything; the guard `tests/docs-contract.sh` fails when a feature has no
test entry here or when any test carries a skip/xfail marker — tests are
never skipped.

## E2E — Backend/API (child image built through the real ONBUILD chain)

- **F2** `tests/run-e2e.sh` › child_builds, packages_installed — a child image builds through the ONBUILD hooks and its `PACKAGES` (curl) are installed.
- **F2** `tests/run-e2e.sh` › configuration_commands_ran — the `CONFIGURATION_COMMANDS` really ran as root during the child build.
- **F3** `tests/run-e2e.sh` › child_runs_unprivileged — the child image runs as `somebody`, not root.

## Image-/Compose-Contract-Tests

- **F1** `tests/config-contract.sh` › apt_works, full_repo_set — apt is functional after minimization and multiverse is enabled.
- **F3** `tests/config-contract.sh` › runtime_user — user `somebody` exists with uid 1000.
- **F4** `tests/config-contract.sh` › no_systemd, no_dbus — the removed infrastructure is really gone (negative checks).
- **F5** `tests/config-contract.sh` › locale_generated, no_recommends, prompt_env — locale archive exists, apt installs without recommends, the prompt is preconfigured.
