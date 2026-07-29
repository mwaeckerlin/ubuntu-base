# Features

Numbered register of every end-user visible feature; a number is never
reused. Every feature is covered by tests listed in [TESTS.md](TESTS.md);
the guard `tests/docs-contract.sh` fails when a feature has no test.

- **F1 — Current Ubuntu with the complete repository set.** Rolling latest
  Ubuntu release with main, restricted, universe and multiverse enabled
  and a working `apt` — for sandboxes where Alpine is not enough.
- **F2 — Ready for derived images (ONBUILD).** A child image only declares
  `ARG PACKAGES` and `ARG CONFIGURATION_COMMANDS` before its `FROM`:
  update/upgrade, package installation and the configuration commands run
  automatically during the child build, which then switches to the
  unprivileged user.
- **F3 — Unprivileged runtime user.** User `somebody` (uid 1000) with home
  directory exists; derived images run non-root by default.
- **F4 — Minimal footprint.** The init/desktop infrastructure (systemd,
  dbus, polkit, login machinery, python stack) is removed while apt keeps
  working — a sandbox base, not a full distribution.
- **F5 — Sensible defaults.** Locale generated (`en_US.UTF-8`, overridable
  via build arg `lang`), lean apt behaviour (no recommends/suggests) and a
  colored prompt showing the container name.
