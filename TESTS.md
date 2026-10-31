# Tests

Register of all tests of the branch `jammy`, grouped by kind and sorted by the [FEATURES.md](FEATURES.md) number each test covers. `npm test` runs everything; the guard `tests/docs-contract.sh` fails when a feature has no test entry here.

## End-to-end

The suite builds a child image through the real ONBUILD chain and runs it.

- **F2** `tests/run-e2e.sh` › child_builds, start_sh_is_command — a child image with a `start.sh` builds, and running it without a command runs that script.
- **F3** `tests/run-e2e.sh` › lang_argument_sets_language — the build argument `lang=C.UTF-8` of the child reaches `LANG`.
- **F5** `tests/run-e2e.sh` › pkg_install_installs — a child installs curl with `$PKG_INSTALL`, and curl runs.

## Image contract

- **F1** `tests/dockerfile-contract.sh` › build_without_warnings, build_without_locale_warnings — `docker build --check` finds no warning, and a build without the cache prints no locale warning.
- **F1** `tests/config-contract.sh` › release_jammy, apt_works, packages_current — the image is Ubuntu `jammy`, apt works, and right after the build no package is left to upgrade.
- **F2** `tests/config-contract.sh` › environment_unchanged, command_and_user_unchanged — the image carries exactly the environment its derived images inherit, the command `/bin/bash` and no `USER`.
- **F2** `tests/config-contract.sh` › onbuild_start_contract — the image carries `ONBUILD ADD start.sh /start.sh` and `ONBUILD CMD ["/start.sh"]`.
- **F3** `tests/config-contract.sh` › locale_generated, prompt_and_language_env — the locale archive exists and `LANG` is `en_US.UTF-8`.
- **F4** `tests/config-contract.sh` › no_recommends, build_packages_removed — apt installs without recommends, and wget and software-properties-common are gone (negative check).
- **F5** `tests/config-contract.sh` › shared_group, prompt_and_language_env — the group `shared-access` has gid 500 and the prompt is preconfigured.

## Workflow contract

- **F6** `tests/workflow-contract.sh` › dockerfile_release, compose_tag, workflow_push_branches, workflow_branch_rule, workflow_shared_build, workflow_all_architectures — Dockerfile, compose file and workflow name `jammy`, a push starts the shared workflow of `mwaeckerlin/scratch`, and no caller setting narrows its architectures amd64 and arm64.
