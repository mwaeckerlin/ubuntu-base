# Ubuntu 22.04 Base Image

`mwaeckerlin/ubuntu-base:jammy` is Ubuntu 22.04 (jammy) with current packages, a working `apt` and a start contract for the images built on it.

Ubuntu supports 22.04 until May 2027, and images that need its packages, such as the legacy line of [mwaeckerlin/nextcloud](https://github.com/mwaeckerlin/nextcloud), build on this tag. It is rebuilt automatically, so a security fix of Ubuntu reaches every image built on it with its next build.

All features are listed in [FEATURES.md](FEATURES.md), all tests in [TESTS.md](TESTS.md).

## Role

This is a **runtime base image**: the images built on it run in production and keep its shell and `apt`. The branch `master` builds the current Ubuntu release as `mwaeckerlin/ubuntu-base:latest`, with a different ONBUILD contract (packages from `ARG PACKAGES`, the unprivileged user `somebody`); the branch `noble` builds Ubuntu 24.04 with the same contract as this one. Lean network services use the scratch-based runtime images such as [mwaeckerlin/php-fpm](https://github.com/mwaeckerlin/php-fpm) and [mwaeckerlin/nginx](https://github.com/mwaeckerlin/nginx).

## Usage

A derived image puts its `start.sh` beside its Dockerfile:

```dockerfile
FROM mwaeckerlin/ubuntu-base:jammy
RUN apt-get update && $PKG_INSTALL apache2
```

The ONBUILD instructions of the base add `start.sh` as `/start.sh` and make it the command of the image. The image runs as root unless the derived image sets `USER`. The build argument `lang` sets `LANG` (default `en_US.UTF-8`).

## Tags

| Tag | Content |
| --- | --- |
| `jammy` | the last build |
| `jammy-YYYYMMDD` | the build of that day |
| `jammy-v<version>` | the version of `package.json` |
| `jammy-v<version>-YYYYMMDD` | that version, built that day |

Every tag is a multi-platform image for amd64 and arm64.

## Environment Variables

| Variable | Default | Description |
| --- | --- | --- |
| `CONTAINERNAME` | `base` | shown in the shell prompt |
| `LANG` | `en_US.UTF-8` | language, set by the build argument `lang` |
| `PKG_INSTALL` | `apt-get install --no-install-recommends --no-install-suggests -y` | install command |
| `PKG_REMOVE` | `apt-get autoremove --purge -y` | remove command |
| `PKG_SEARCH` | `apt-cache search` | search command |
| `ALLOW_USER` | `chown -R somebody:somebody` | ownership command |
| `SHARED_GROUP_NAME`, `SHARED_GROUP_ID` | `shared-access`, `500` | group for volumes shared between containers |

## Build and Test

```bash
npm run build
npm test
```

`npm test` runs the docs contract (every feature has a test), the Dockerfile contract (no build warning), the workflow contract (Dockerfile, compose file and workflow name `jammy`), the config contract (release, current packages, apt, locale, lean apt defaults, shared group, the inherited environment, the ONBUILD instructions) and an end-to-end test that builds a child image through the ONBUILD hooks and runs its `start.sh`.

## Publishing

`.github/workflows/docker.yml` calls the shared workflow of [mwaeckerlin/scratch](https://github.com/mwaeckerlin/scratch#publishing-on-docker-hub): every push to `jammy` builds, tests and publishes the image for amd64 and arm64. GitHub starts scheduled runs on the default branch only, so the hourly run of `master` starts the workflow on `jammy`, which rebuilds the image when `ubuntu:jammy` changed or the image is a week old.

The branch is maintained in place: changes are committed on `jammy` itself, and it is never regenerated from `master`, because that would replace its Dockerfile and its ONBUILD contract with the ones of `master`.
