# Basic Ubuntu Docker Image

Use as base for containers where a simple Alpine is not enough and you need an Ubuntu, e.g. sandboxes you access through SSH.

Setup is similar to [mwaeckerlin/very-base](https://github.com/mwaeckerlin/very-base).

All features are listed in [FEATURES.md](FEATURES.md), all tests in [TESTS.md](TESTS.md).

## Role: production runtime / sandbox base

This is a **runtime base image** that is **deployed** — use it as the base of a
container that runs in production (typically an interactive SSH sandbox, e.g.
[mwaeckerlin/hermes] and [mwaeckerlin/openclaw]). Unlike the headless
scratch-based runtime images ([mwaeckerlin/nodejs], [mwaeckerlin/php-fpm],
[mwaeckerlin/nginx]), it **deliberately ships a full shell, `apt` and a complete
Ubuntu userland**, because an interactive sandbox needs them — the opposite
trade-off to the minimal-attack-surface runtime images. Keep it for exactly that
use case; for lean network services prefer the scratch-based runtime images.

Child images built on top switch to the non-root user automatically via the
`ONBUILD USER ${RUN_USER}` hook (see below); the base image itself is root with a
shell by design, so it can install packages and run an SSH daemon.

[mwaeckerlin/hermes]: https://github.com/mwaeckerlin/hermes
[mwaeckerlin/openclaw]: https://github.com/mwaeckerlin/openclaw
[mwaeckerlin/nodejs]: https://github.com/mwaeckerlin/nodejs
[mwaeckerlin/php-fpm]: https://github.com/mwaeckerlin/php-fpm
[mwaeckerlin/nginx]: https://github.com/mwaeckerlin/nginx

## Features

- Ubuntu with all official repositories (main, restricted, universe, multiverse)
- Non-root user `somebody` (group `somebody`) with home `/home/somebody`
- Locale configured via build arg `lang` (default: `en_US.UTF-8`)
- Colored prompt with container name
- Minimal footprint: unnecessary packages removed during build
- ONBUILD support for child images

## ONBUILD Behavior

Child images automatically get:

1. `apt-get update && apt-get dist-upgrade -y`
2. `$PKG_INSTALL ${PACKAGES}` — install packages defined via `ARG PACKAGES`
3. `bash -c "${CONFIGURATION_COMMANDS}"` — run commands defined via `ARG CONFIGURATION_COMMANDS`
4. `USER ${RUN_USER}` — switch to non-root user

This means, your child is automatically not `root`, and all you need to do as `root` goes to `CONFIGURATION_COMMANDS`, respectively packages to install go to `PACKAGES`.

### Security trade-off

`PACKAGES` and `CONFIGURATION_COMMANDS` are executed as shell during the child
**build** (`$PKG_INSTALL ${PACKAGES}`, `bash -c "${CONFIGURATION_COMMANDS}"`).
They are build-time, image-author-controlled inputs — treat them like source
code: a typo becomes a build failure, and anything you put there runs with build
privileges. Do not feed untrusted values into these args.

## Usage

```dockerfile
ARG PACKAGES="nginx curl"
ARG CONFIGURATION_COMMANDS="echo 'done'"
FROM mwaeckerlin/ubuntu-base
```

The `PACKAGES` and `CONFIGURATION_COMMANDS` args must be declared **before** `FROM`.

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `CONTAINERNAME` | `base` | Shown in shell prompt |
| `RUN_USER` | `somebody` | Non-root runtime user |
| `RUN_GROUP` | `somebody` | Runtime user group |
| `RUN_HOME` | `/home/somebody` | Home directory |
| `PKG_INSTALL` | `apt-get install ...` | Install command helper |
| `PKG_REMOVE` | `apt-get autoremove ...` | Remove command helper |
| `PKG_CLEANUP` | remove + clean | Full cleanup command (`bash -c "$PKG_CLEANUP"`) |
| `ALLOW_USER` | `chown -R somebody:somebody` | Ownership fix helper |

## Build and Test

```bash
npm run build       # docker compose build
npm test            # docs contract + config contract + ONBUILD e2e
```

`npm test` runs the docs contract (every feature in [FEATURES.md](FEATURES.md)
has a test in [TESTS.md](TESTS.md), no skipped tests), the config contract
(apt works, full repository set, runtime user, locale, lean apt defaults —
plus negative checks that systemd and dbus are really gone) and an end to
end test that builds a child image through the ONBUILD hooks and verifies
packages, configuration commands and the unprivileged user.
