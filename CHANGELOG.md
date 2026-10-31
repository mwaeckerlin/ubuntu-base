# Changelog

- 2026-10-31 **1.0.1**
    - The branch no longer carries the script that reset `jammy`, `noble` and `latest` to `master`; running it would have replaced the start contract of `ubuntu-base:noble` with the one of `master`

- 2026-10-31 **1.0.0**
    - The image `ubuntu-base:noble` is published for amd64 and arm64 and rebuilt automatically, so the security fixes of Ubuntu 24.04 reach it and every image built on it
    - It is also published under its build day and its version: `noble-YYYYMMDD`, `noble-v1.0.0`, `noble-v1.0.0-YYYYMMDD`
    - The start contract for derived images stays as it was: a `start.sh` beside the Dockerfile becomes the command of the image
