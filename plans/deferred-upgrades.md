# Deferred upgrades

Upgrades a dependency sweep tried and held back, with why and the manual steps.

## Inside the 4-day cooldown on 2026-10-29

Take these on the next sweep: activerecord-import 3.0.1 (fixes a 3.0.0 `synchronize`
regression this app doesn't hit), capybara-playwright-driver 0.5.14, sass 1.107.0,
autoprefixer 10.6.2, postcss 8.5.32. The newest releases past the cooldown (sass 1.106.1,
autoprefixer 10.6.1, postcss 8.5.31) are in.

Yarn 1 has no cooldown setting, so check each npm release's age by hand
(`npm view <pkg> time`), transitive ones too: `yarn upgrade` resolves every new range to the
newest release. To land a caret range on an older release without editing `yarn.lock`, seed an
empty cache with only the allowed versions (a scratch project that depends on them, with
`resolutions` for the transitive ones), fill it from the current lock
(`yarn install --frozen-lockfile --force --cache-folder <dir>`), then run
`yarn install --offline --cache-folder <dir>`: offline, yarn resolves new ranges against what
the cache holds.
