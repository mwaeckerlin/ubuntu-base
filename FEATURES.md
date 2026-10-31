# Features

Numbered register of the features of the branch `jammy`, recorded as found in its Dockerfile; a number is never reused. Every feature is covered by tests listed in [TESTS.md](TESTS.md); the guard `tests/docs-contract.sh` fails when a feature has no test.

- **F1 — Ubuntu 22.04 with current packages.** The image is Ubuntu `jammy` with every package upgraded during the build and a working `apt`, so a security fix Ubuntu publishes reaches the image with its next build.
- **F2 — Start contract for derived images.** A child image puts a `start.sh` beside its Dockerfile and writes `FROM mwaeckerlin/ubuntu-base:jammy`: its build adds the script as `/start.sh` and makes it the command of the image.
- **F3 — Language.** The locale `en_US.UTF-8` is generated and set as `LANG`; a child sets another language with the build argument `lang`.
- **F4 — Lean package set.** `apt` installs no recommended and no suggested packages, and the packages the build needs only while it runs (`lsb-release`, `wget`, `software-properties-common`, `gpg-agent`) are removed again.
- **F5 — Shell environment for derived images.** A coloured prompt shows the container name (`CONTAINERNAME`), the variables `PKG_INSTALL`, `PKG_REMOVE`, `PKG_SEARCH` and `ALLOW_USER` hold the package and ownership commands, and the group `shared-access` with gid 500 exists for volumes shared between containers.
- **F6 — Published for amd64 and arm64.** Every push to the branch builds the image natively for both architectures and publishes it on Docker Hub as `jammy`, `jammy-YYYYMMDD`, `jammy-v<version>` and `jammy-v<version>-YYYYMMDD`; the hourly check of the default branch rebuilds it when `ubuntu:jammy` changed or the image is a week old.
