# Basic Ubuntu Docker Image

Use as base for containers where a simple Alpine is not enough and you need an Ubuntu, e.g. sandboxes you access throigh SSH.

Setup is similar to [mwaeckerlin/very-base](https://github.com/mwaeckerlin/very-base)

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
| `CLEANUP` | remove + clean | Full cleanup command |
| `ALLOW_USER` | `chown -R somebody:somebody` | Ownership fix helper |

## Build

```bash
docker compose build
```
