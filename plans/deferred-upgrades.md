# Deferred upgrades

Upgrades a dependency sweep tried and held back, with why and the manual steps.

## Node 22.4.1 blocks three of them (2026-10-29 sweep)

The `mise.toml` / `.node-version` / `Dockerfile` Node pin is 22.4.1. Three tools now need
`require(esm)` or an engines floor of Node 22.12+:

| Held | At | Needs | Symptom on 22.4.1 |
| --- | --- | --- | --- |
| `postcss-cli` (npm) | 11.0.1 | 12.0.0 pulls yargs 18 (`node ^22.12.0`) | `yarn install` refuses: "The engine node is incompatible" |
| `sass` (npm) | `<1.100.0` cap | 1.100+ uses chokidar 5 (ESM-only) | `yarn build:css` dies with `ERR_REQUIRE_ESM` (already in CLAUDE.md's holds) |
| `herb lint` | any herb gem | `npx @herb-tools/linter` resolves 0.11.x, whose core requires an ESM module | `bundle exec herb lint app/` dies with `ERR_REQUIRE_ESM`, on the old herb 0.10.3 gem too, so the hk `herb-lint` step and CI's lint job fail whenever an ERB file changes |

Manual steps: bump Node to the current 22.x LTS (or 24) in `mise.toml`, `.node-version` and
the `Dockerfile` `ARG NODE_VERSION` together (`scripts/check_version_sync.sh` checks they agree),
then `yarn upgrade postcss-cli@^12` and lift the sass cap, then run `yarn build:css`, `bin/rails
test`, `bin/rails test:system` and `bundle exec herb lint app/`.

## Inside the 4-day cooldown on 2026-10-29

Take these on the next sweep: activerecord-import 3.0.1 (fixes a 3.0.0 `synchronize`
regression this app doesn't hit), capybara-playwright-driver 0.5.14, autoprefixer 10.6.2,
postcss 8.5.32. Yarn 1 has no cooldown setting, so check each npm release's age by hand
(`npm view <pkg> time`).
