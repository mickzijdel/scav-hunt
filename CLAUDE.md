# CLAUDE.md

## What this app is

Scoring website for the Bedlam Theatre / EUTC scavenger hunt. Teams are `User` records
(`role` enum: `team` / `scorer` / `admin`, Devise-authenticated, CanCanCan-authorised via
`app/models/ability.rb`); scorers award `regular_points` and `bonus_points` per
`Challenge` through a `Result` join model, and the live scoreboard, per-team scoring screen
and points-over-time statistics chart update over ActionCable.

Main surfaces (`config/routes.rb`): `home#index` (scoreboard, also `format.json`),
`scoring#index` / `scoring#score` / `POST scoring/update`, `challenges` (with CSV
`import_form` / `import` / `export`), `users`, `group_permissions`, `settings`,
`statistics`, and `ActionCable` mounted at `/cable`.

## Key package versions

Read from the manifests in this repo. Do not take versions from memory — re-read the file.

| Package | Version | Source |
| --- | --- | --- |
| Ruby | 3.3.3 | `.ruby-version`, `mise.toml`, `Dockerfile` `ARG RUBY_VERSION` |
| Rails | 8.1.3.1 | `Gemfile.lock` (`Gemfile` pins `~> 8.1.3` with a `>= 8.1.3.1` security floor) |
| mysql2 | 0.5.7 | `Gemfile.lock` (`Gemfile`: `~> 0.5`) |
| Devise | 5.0.4 | `Gemfile.lock` |
| CanCanCan | 3.6.1 | `Gemfile.lock` |
| Simple Form | 5.4.1 | `Gemfile.lock` |
| turbo-rails (gem) | 2.0.23 | `Gemfile.lock` |
| stimulus-rails (gem) | 1.3.4 | `Gemfile.lock` |
| Propshaft | 1.3.2 | `Gemfile.lock` |
| Puma | 8.0.2 | `Gemfile.lock` |
| redis | 5.4.1 (`Gemfile`: `~> 5.3`, capped below 6 - see comment) | `Gemfile.lock` |
| jbuilder | 2.15.1 | `Gemfile.lock` |
| activerecord-import | 2.2.0 | `Gemfile.lock` |
| RuboCop | 1.89.0 (+ rubocop-rails-omakase 1.0.0 - held, see below; rubocop-minitest 0.40.0; rubocop-mick 0.1.0 from git) | `Gemfile.lock` |
| Brakeman | 8.0.5 | `Gemfile.lock` |
| herb | 0.10.3 | `Gemfile.lock`, `.herb.yml` `version:` |
| Capybara / selenium-webdriver | 3.40.0 / 4.46.0 | `Gemfile.lock` |
| Bundler | 2.5.13 | `Gemfile.lock` (`BUNDLED WITH`) |
| Node | 22.4.1 | `.node-version`, `mise.toml`, `Dockerfile` `ARG NODE_VERSION` |
| Yarn | 1.22.19 | `mise.toml`, `Dockerfile` `ARG YARN_VERSION` |
| @hotwired/turbo-rails | 8.0.23 (spec `^8.0.9`) | `yarn.lock` / `package.json` |
| @hotwired/stimulus | 3.2.2 | `yarn.lock` / `package.json` |
| @rails/actioncable | 8.1.301 | `yarn.lock` / `package.json` |
| Bootstrap | 5.3.8 (+ bootstrap-icons 1.13.1, @popperjs/core 2.11.8) | `yarn.lock` / `package.json` |
| esbuild | 0.28.1 | `yarn.lock` / `package.json` |
| sass | 1.99.0 (spec `>=1.78.0 <1.100.0` - capped, see below) | `yarn.lock` / `package.json` |
| billboard.js | 4.0.3 | `yarn.lock` / `package.json` |
| d3 | 7.9.0 | `yarn.lock` / `package.json` |
| postcss / postcss-cli / autoprefixer | 8.5.26 / 11.0.1 / 10.5.4 | `yarn.lock` / `package.json` |

`mise.toml` is the single source of truth for ruby/node/yarn and must stay in lockstep with
`.ruby-version`, `.node-version` and the `Dockerfile` ARGs (`RUBY_VERSION`, `NODE_VERSION`,
`YARN_VERSION`). Change all of them together.

Also pinned in `mise.toml` (spec `latest`, resolved versions recorded in `mise.lock`):
`hk`, `pkl`, `gitleaks`, `zizmor`, `actionlint`.

## Running the app

```sh
mise install          # provisions ruby, node, yarn and the dev-env tooling
bundle install
yarn install
bin/rails db:setup    # or bin/setup
bin/dev               # foreman -f Procfile.dev
```

`Procfile.dev` runs three processes:

- `web`: `env RUBY_DEBUG_OPEN=true bin/rails server` (port 3000, `bin/dev` exports `PORT` default 3000)
- `js`: `yarn build --watch` (esbuild → `app/assets/builds`)
- `css`: `yarn watch:css` (nodemon → `yarn build:css` = sass + postcss/autoprefixer)

Database: MySQL, adapter `mysql2`. `config/database.yml` development/test connect to
`localhost` as user `scav_hunt` with an **empty password**, databases
`scav_hunt_development` / `scav_hunt_test`. Run MySQL in a Docker container publishing
3306 on localhost. Note `docker-compose.yml` is the **production** stack (`rails` +
`database` = `mysql:8.3` + `redis` = `redis:7.4`) and its `database` service does *not*
publish 3306 to the host, so it is not a drop-in dev database; the production Rails
container maps host `2024` → container `3000` and reads `SCAV_HUNT_DATABASE_*`,
`RAILS_MASTER_KEY`, `REDIS_URL`, `ACTION_CABLE_*` from the environment.

## Testing

```sh
bin/rails test          # models, services, channels
bin/rails test:system   # Capybara + selenium-webdriver (Chrome)
```

Fixtures in `test/fixtures/*.yml` are loaded for every test (`test/test_helper.rb`, `fixtures :all`),
tests run parallelised with threads, and SimpleCov writes `coverage/index.html`.
CI runs `bin/rails db:test:prepare test test:system` against a `mysql:8.4` service.

## Lint / pre-commit

```sh
hk install            # installs the git pre-commit hook
hk run check --all    # run every gate over the whole repo
hk run fix            # autofix what can be autofixed
```

Gates defined in `hk.pkl` (all three hooks — `pre-commit`, `fix`, `check` — run the same
`linters` mapping; most are glob-gated):

| Step | Command |
| --- | --- |
| `rubocop` | `bin/rubocop` / fix `bin/rubocop -A` |
| `test` | `bin/rails test` |
| `herb-analyze` | `bundle exec herb analyze app/` |
| `herb-lint` | `bundle exec herb lint app/` / fix `--fix` |
| `exec-bit-scripts` | shebang files must be mode 100755 in the git index |
| `debride` | `bundle exec debride --exclude vendor,node_modules,tmp,log .` |
| `flay` | `bundle exec flay app lib` (advisory) |
| `jscpd` | `bash scripts/run-jscpd.sh ruby,erb,javascript,typescript,css,scss,sass,vue` |
| `brakeman` | `bundle exec brakeman -q --no-pager --exit-on-warn` |
| `bundler-audit` | `bundle exec bundle-audit check` (best-effort `update` first) |
| `importmap-audit` | skipped — no `bin/importmap` (this app bundles with esbuild) |
| `fasterer` | `bundle exec fasterer \|\| true` (advisory) |
| `database_consistency` | `bundle exec database_consistency`, skipped when no DB is reachable |
| `actionlint` | `actionlint -shellcheck= {{ files }}` |
| `zizmor`, `gitleaks`, `check-added-large-files` | hk builtins |

`.github/workflows/ci.yml` mirrors these gates across the `lint`, `test`, `scan`,
`gitleaks`, `actions-lint` and `audit` jobs, so local and CI checks cannot drift. Keep them
in sync when changing either. CI triggers on push to `master` (the default branch) and on
every pull request.

## Known pre-existing issues

These gates are currently red for reasons that predate the tooling. Do not treat them as
regressions caused by a change you are making.

1. **`bin/rails test` — 26 runs, 4 errors.** Three in `test/services/statistics_service_test.rb`:
   `NoMethodError: undefined method 'min' for nil` at `app/services/statistics_service.rb:36`
   in `generate_time_intervals` (`start_time` is nil when the `chart_start_time` setting is
   absent). One in `test/channels/application_cable/connection_test.rb`.
2. **`bin/rubocop` — 201 offences (198 autocorrectable)** in four files:
   `config/initializers/devise.rb`, `config/initializers/simple_form.rb`,
   `config/initializers/simple_form_bootstrap.rb`,
   `db/migrate/20240828214914_update_users_to_challenges.rb`. Mostly `Style/StringLiterals`.
   Fix with `bin/rubocop -A`.
3. **`bundle exec herb analyze app/` and `herb lint app/` both fail** on one genuine markup
   bug: `app/views/layouts/_navbar.html.erb` line 1 has a stray comma between two HTML
   attributes (`bg-body-tertiary", data-bs-theme="dark"`). Removing the comma makes
   `herb analyze` fully clean.
4. **`bundle exec brakeman -q --no-pager --exit-on-warn` — 2 warnings.** Mass Assignment
   (`PermitAttributes`) at `app/controllers/users_controller.rb:56` permitting `:role`, and
   possible SQL injection at `app/services/statistics_service.rb:22`
   (`team.results.where("#{time_column} <= ?", interval)`).
5. ~~**`bundle exec bundle-audit check` — many CVEs.**~~ **Cleared.** The dependency-upgrade
   pass took the tree to Rails 8.1.3.1 (via 8.0.5.1), puma 8.0.2, devise 5.0.4 and the
   transitive rack/nokogiri/rexml/addressable/bcrypt/websocket-driver fixes.
   `bundle exec bundler-audit check` now reports **No vulnerabilities found**. Keep it that way.
6. **`.herb.yml` carries an adoption baseline**: 11 herb rules with pre-existing offences are
   parked with `enabled: false`. That is a to-do list, not a policy — fix the offences (many
   are `herb lint app/ --fix`-able) and delete the entry to re-enable each rule.
7. **`.jscpd.json` sets `threshold: 1.1`** rather than the standard's `0`, because of two
   pre-existing clones: `app/assets/stylesheets/login.css` ~ `app/assets/stylesheets/scoreboard.css`,
   and two blocks of `test/system/home_test.rb`. Return the threshold to `0` once those are
   de-duplicated.

## Deliberate version holds

Four dependencies are pinned *below* their latest release on purpose. Each carries the reason
inline in `Gemfile` / `package.json`; do not "helpfully" unpin them without dealing with the
cause.

| Held | At | Why |
| --- | --- | --- |
| `redis` (gem) | `~> 5.3` | Action Cable's Redis subscription adapter does `gem "redis", ">= 4", "< 6"` at require time, so redis 6 raises `Gem::LoadError` the moment production's `adapter: redis` loads. Still true on Rails 8.1. The test suite cannot catch it — `config/cable.yml` uses the test adapter. |
| `cssbundling-rails` | `= 1.4.1` | 1.4.2+ lists `yarn.lock` as a **bun** lock file and checks bun first, so on any machine with bun installed `css:build` silently switches to `bun run build:css` and drops an untracked `bun.lock`, despite yarn 1 being pinned in `mise.toml`, the `Dockerfile` and CI. |
| `sass` (npm) | `>=1.78.0 <1.100.0` | sass 1.100.0 moved its CLI watcher to the ESM-only chokidar 5, so `yarn build:css` dies with `ERR_REQUIRE_ESM` on the pinned Node 22.4.1 (`require(esm)` needs Node 22.12+). Lifting the cap means bumping the Node pin. |
| `rubocop-rails-omakase` | 1.0.0 | 1.1.0 registers rubocop-minitest via `plugins:` instead of `require:`, enabling extra Minitest cops. The only offence is `Minitest/RefuteFalse` at `test/system/settings_test.rb:36` — autocorrectable with `bin/rubocop -A`; fix it and drop the hold. |

## Supply-chain seasoning

`Gemfile` line 1 pins `source "https://rubygems.org", cooldown: 4` and `mise.toml` sets
`minimum_release_age = "4d"`. Both are deliberate: a newly published version must age four
days before it can be resolved. Do not remove them.

Note that `BUNDLED WITH` is Bundler 2.5.13, which predates native `cooldown:` support, yet the
cooldown *is* applied (it is also set in the user-level `~/.bundle/config`) and it over-filters:
it held Rails at 7.2.3 when 7.2.3.2 was already nine days old. That is why the `Gemfile` spells
security floors out explicitly (`gem "rails", "~> 8.1.3", ">= 8.1.3.1"`) rather than trusting
the resolver to pick the newest allowed version.

## Secrets

`config/master.key` and `.env` (`/.env*` in `.gitignore`) are gitignored and must never be
committed. Production reads `RAILS_MASTER_KEY`, `DATABASE_PASSWORD`, `DATABASE_NAME` and
`HOST_URL` from the environment (see README.md).
