# scav-hunt — whole-repo review, 2026-08-07

Five parallel reviewers (Hotwire, domain layer, security, views/tests, dev-env) plus an
overseer pass. Every finding below cites code that was actually read; the ones marked
**[verified]** were additionally reproduced by running something.

## Baseline on arrival

Both suites were **already red before any change**:

| Suite | Result |
|---|---|
| `bin/rails test` | 26 runs, 35 assertions, **0 failures, 4 errors** (stable across 3 runs) |
| `bin/rails test:system` | 46 runs, 87 assertions, **18 failures, 2 errors** |

The 4 unit errors are 3 × `StatisticsService` (§2) and 1 × `ApplicationCable::ConnectionTest`
(§13 — a broken *test*, not broken auth). Most of the 18 system failures are one bug (§1).

Repo also arrived mid-interactive-rebase with a conflicted `Dockerfile`; resolved and completed.

---

## 🔴 High severity

### 1. The layout `<h1>` is ERB-commented out — every page has no heading **[verified]**
- **Where:** `app/views/layouts/application.html.erb:31`
- **Finding:** `<h1><%#= @title %></h1>`. `<%#=` is a *comment* tag. 14 controller actions set
  `@title`; the `<title>` tag still uses it, the `<h1>` never renders.
- **Evidence:** screenshot `tmp/screenshots/failures_test_visiting_the_index_as_admin.png` shows a
  fully-rendered page with no heading. Introduced by `89093a8 "Changes visual design of
  scoreboard page"` — the author wanted no heading on the *scoreboard* and removed it everywhere.
- **Impact:** Empty first heading on every page (WCAG blocker); 14 `assert_selector "h1"`
  assertions across 6 system-test files cannot pass.
- **Fix:** NOT a plain uncomment — that regresses the scoreboard's intended design. Render
  conditionally and let the scoreboard opt out:
  `<% if @title.present? && !@hide_heading %><h1><%= @title %></h1><% end %>`, or move to
  `content_for :heading`.

### 2. `StatisticsService` crashes on any fresh install — `chart_start_time` is never set **[verified]**
- **Where:** `app/services/statistics_service.rb:7,9,36`
- **Finding:** `Setting.get("chart_start_time")` returns `nil`; `nil.min` raises at line 36.
  `chart_start_time` appears in exactly two places repo-wide — `setting.rb:6` (declared) and
  `statistics_service.rb:7` (read). It is **never seeded, never fixtured**, and
  `SettingsController#index`'s `find_or_create_by` can't create it either (presence validation on
  `value` fails, returning an unpersisted record).
- **Impact:** `/statistics` is a hard 500 on any install where an admin hasn't manually typed that
  setting. 3 of the 4 unit errors; all 4 statistics system tests.
- **Also:** line 9 has the identical unguarded `Setting.get("scoreboard_end_time").advance`.
- **Fix:** `start_time = Setting.get("chart_start_time") || Result.minimum(time_column) || Time.current`,
  guard the `.advance`, and clamp so `end_time >= start_time`.
- **Test caveat [verified]:** fixing the service is *not* enough for
  `"calculates points correctly"` to pass. `settings.yml` pins the hunt to 2024-09-28 while
  `results.yml` sets no `created_at` (stamped at load time), so the chart window excludes every
  fixture row and the assertion of 1100 sees 0. The test's window must be fixed too.

### 3. Seeded admin credentials in a public repo, auto-created on deploy **[verified]**
- **Where:** `db/seeds.rb:5-7`, `bin/docker-entrypoint:12`
- **Finding:** Seeds create a working `admin` (role 2) with a hardcoded 8-char password, plus a
  scorer and a team on the same password. `docker-entrypoint` runs `db:prepare`, which seeds on a
  fresh database. Upstream is public: `github.com/EdinburghUniversityTheatreCompany/scav-hunt`.
- **Evidence:** ran the seeds on a scratch DB. They crash at line 14 — but `db:seed` is **not
  transactional**, so all three users commit first and survive:
  ```
  id  email                       role
  1   admin@bedlamtheatre.co.uk   2
  ```
- **Impact:** Anyone reading the public repo can sign in as admin (`can :manage, :all`). No login
  throttling, no `lockable`, 6-char password floor.
- **Fix:** Gate behind `Rails.env.local?` or an env-supplied password. **Rotate the password on
  any deployed instance** — fixing the code does not remove an account that already exists.

### 4. ActionCable channels stream any `user_id` the client asks for
- **Where:** `app/channels/scoring_channel.rb:2-6`, `app/channels/group_updates_channel.rb:2-7`
- **Finding:** `subscribed` does `User.find(params[:user_id])` then `stream_for user`, never
  consulting `current_user`. `#receive` *is* correctly gated — reads were simply missed.
- **Impact:** Any logged-in team can subscribe to a rival's stream and watch live per-challenge
  scores while the scoreboard is deliberately hidden. `GroupUpdatesChannel` leaks the rendered
  challenge-list HTML for groups the attacker has no permission for.
- **Fix:** `reject unless user == current_user || Ability.new(current_user).can?(:manage, :scoring)`.
  Structurally better: `turbo_stream_from` signs stream names (§8).

### 5. `/home/index.json` is unauthenticated and ignores `scoreboard_visible`
- **Where:** `app/controllers/home_controller.rb:9-23`
- **Finding:** The HTML branch respects `@scoreboard_visible`; the JSON branch doesn't. No
  `authenticate_user!` anywhere in `app/` (`ApplicationController` is 6 lines, only a `rescue_from`).
- **Impact:** `curl https://host/home/index.json` returns full standings while hidden — and hands
  out the team IDs that make §4 trivial to exploit.
- **Second bug, same method:** `Rails.cache.fetch("teams_json")` uses a **constant key** for an
  **ability-dependent payload** (`user.rb:63` merges scorer-only stats). Whoever polls first that
  minute decides what everyone gets, so a scorer's poll leaks completion stats to teams and
  anonymous visitors.
- **Fix:** `head :forbidden unless @scoreboard_visible`; key the cache `"teams_json/#{scope}"`.

### 6. CSV import silently drops invalid rows and reports success
- **Where:** `app/controllers/challenges_controller.rb:83-111`
- **Finding:** `activerecord-import` defaults to `validate: true` and collects rejects into
  `failed_instances` — the return value is discarded, then `notice: "Challenges imported
  successfully."`. A misspelled header makes `row["GroupID"]` nil for every row, so
  `find_or_initialize_by(number: nil)` returns the same record each iteration and nothing imports,
  still reporting success.
- **Impact:** Silent data loss with positive feedback, on a task performed once, right before the
  event. The worst failure mode in the app.
- **Fix:** Validate headers up front; branch on `result.failed_instances`.
- **Bonus:** the `# TODO: The alerts don't show up? Probably a turbo thing` is **not** Turbo — it's
  `flash[:alert]` where `flash.now[:alert]` is needed, plus a missing
  `status: :unprocessable_entity` (Turbo discards 200s on form submits). Also `print(e)` writes to
  stdout, not the log.

### 7. Deleting a user with any score is an unhandled 500
- **Where:** `app/models/user.rb:10-12`, `app/controllers/users_controller.rb:48-51`
- **Finding:** `has_many :results` / `:group_permissions` with **no `dependent:`**, but the DB has
  hard FKs (`schema.rb:67,69`). `@user.destroy` raises `InvalidForeignKey`. `Challenge` gets this
  right; `User` never did.
- **Impact:** Admin clicks Destroy on the first row (Team 1, who has fixture results) → 500.
- **Fix:** `dependent: :destroy` on results (honours `Result#ensure_zero_points`),
  `dependent: :delete_all` on permissions, and branch on `if @user.destroy`.

### 8. The Hotwire layer is entirely hand-rolled — five parallel update mechanisms **[verified]**
- **Evidence:** `turbo_frame_tag`, `turbo_stream_from`, `broadcasts_to`, `turbo_stream.` → **0 hits**.
  `*.turbo_stream.erb` → **none**. `turbo-rails` is imported and unused.
- **Finding:** Every reactive region is bespoke: a 5s `setInterval` poller, two ActionCable channels
  (one shipping HTML strings to `innerHTML`), two independent write paths for the same save, and
  hand-rolled `fetch` + CSRF + optimistic rollback for permissions.
- **Impact:** This *is* the "overcomplicated" feeling — but the cause is the absence of Turbo, not
  its misuse. Several 🔴 bugs above live specifically in this plumbing.
- **Fix:** Collapse onto `turbo_stream_from` + `broadcasts_to` + `.turbo_stream.erb`.
  **≈300 net lines removable**; kills §4 structurally and §11 outright.

---

## 🟡 Medium severity

9. **`Result#after_update_data` is a mutating getter** (`result.rb:35-54`) — nils `updated_by_id`
   as a side effect of being read, and is called twice per save, so the HTTP fallback always
   reports `updated_by: nil` and the scorer's own edits flash as someone else's.
10. **Broadcasts and cache-clears fire in `after_save`, before commit** (`result.rb:9`,
    `user.rb:20`) — clients can be shown a score that then rolls back. Use `after_commit`.
11. **`Rails.cache.fetch("teams_ranked") { User.teams_ranked }`** (`home_controller.rb:4`) caches an
    **unloaded relation** — it caches nothing. Invisible in dev/test (`:null_store`).
12. **`/statistics` issues ~1,900 queries per load** (`statistics_service.rb:18-27`) — teams ×
    intervals × 2 calls, and the `includes(:results)` is discarded by the subsequent `.where`.
13. **`User#total_points` shadows the `teams_ranked` SQL alias** (`user.rb:41-43`) — the aggregate is
    computed, discarded, then re-queried per team. Same `.where`-kills-preload mistake in
    `Challenge#completion_stats` (`challenge.rb:19-29`, 3 queries per row).
14. **Zero-point challenges disagree across pages** — `result.rb:26` and `challenge.rb:21` say
    "Completed", `user.rb:46` says "Not Attempted". Three implementations of one concept.
15. **`Setting#parsed_value` uses `DateTime.parse`** (`setting.rb:33-42`) — zone-blind, so a UK
    admin typing a local time gets a 1-hour shift during BST. `config.time_zone` is unset.
16. **`Setting.set` returns a discarded boolean** — clearing a setting flashes success and keeps the
    old value. `SettingsController#index` also fires 3 doomed INSERTs per render.
17. **`parallelize(with: :threads)`** (`test_helper.rb:11`) — threads share one DB and all global
    state, while two system tests mutate `Setting` in `setup` and one calls `Result.delete_all`.
    Latent, not currently flaky **[verified stable ×3]**, but wrong. Also move `better_errors` to
    `group :development`.
18. **Coverage is measuring a subset** — bare `SimpleCov.start` + `eager_load` false means files
    never `require`d aren't counted. With zero controller tests, **no controller is in the
    denominator**. The 91.29% is not what it appears.
19. **No controller/integration tests at all**; `test/factories/` is entirely dead (never invoked,
    references a `:user` factory that doesn't exist); every fixture user has
    `encrypted_password: "NA"`, so **no fixture user can sign in**.
20. **Accessibility blockers** — group-permission checkboxes and scoring inputs have no accessible
    names; search/sort inputs are placeholder-only; live-updating regions have no `aria-live`;
    `<html>` has no `lang`; the navbar logo link has no accessible name; charts have no text
    alternative; save state is colour-only with an unguarded animation.
21. **No `check_authorization`** — authorization is opt-in per controller. It's currently closed by
    convention, and `home#index` already proves the convention fails.
22. **Devise `:registerable` exposes public sign-up** — inert only because `role`/`name` presence
    validation rejects it. One `default: 0` migration away from open registration.
23. **No login rate limiting**, no `lockable`, `paranoid` off (account enumeration), CSP and
    Permissions-Policy entirely commented out.

## 🟢 Low severity

24. `ScoringController#score` continues executing after `redirect_to` (no `return`).
25. `ScoringController#update` and `ScoringChannel#receive` are the same 8 lines twice.
26. Sorting by Completed/Partially/Not Attempted throws a `TypeError` — the cells carry
    `data-challenge-updates-target`, the sorter looks for `data-column`.
27. Dead code: navbar dropdown branch + `@current_path` (never assigned, so `active` never applies);
    5 unreachable Devise views; `app/javascript/channels/index.js` and its unused `window.App.cable`;
    `Ability` rule for a resource with no routes; commented-out `ApplicationJob`.
28. `application/forms/_errors` hardcodes "this user" but is shared with the challenge form.
29. Duplicate DOM ids on the settings page; `users/_user.html.erb` reads `@user` not its local.
30. CSV export algorithm lives in an ERB template (untestable — and its "test" asserts nothing).
31. Two no-op tests: `assert_raise(Capybara::NotSupportedByDriverError)` around the export
    assertion, and case-mismatched `assert_no_selector`s guarding an authorization boundary.
32. 26 seconds of `sleep` in system tests where Capybara waiting matchers belong.
33. `login.css` / `scoreboard.css` share a byte-identical block including a dead `-webkit-`
    gradient and a global `*` reset applied after Bootstrap; `2vw`/`5vw` text is ~7.5px on a phone.
34. `challenges.number` is unique in the model but has no DB index; `results` has the opposite
    (unique index, no model validation → `RecordNotUnique` 500s).
35. 22 `console.log`s ship to production; one logs a payload with user IDs.

---

## Dev-env compliance

Brought to standard **v22** on branch `dev-env-standards` (11 atomic commits, no `app/` changes,
suite verified unchanged at 26 runs / 4 errors). Adds `mise.toml` + `mise.lock`, `hk.pkl`
pre-commit, gitleaks, jscpd, zizmor, actionlint, Ruby lint/audit gems incl. `rubocop-mick`,
`CLAUDE.md`, refreshed `README.md`, Dependabot cooldown, and a hardened CI workflow
(SHA-pinned actions, `permissions:` block, and a fix for CI triggering on `main` when the default
branch is actually **`master`** — so CI had never run on pushes to the default branch).

Deviations to note: `strong_migrations` omitted (runtime gem, out of granted scope);
adding `rubocop-mick` pulled rubocop 1.66 → 1.89 (verified zero new offences); `jscpd`
threshold set to 1.1 not 0; **`hk install` must be run after merging** (the agent removed the
hook because the shared git dir would have broken commits on `master`).

---

## Recommended order

1. **§3 rotate the deployed admin password** — outside the codebase, do it first.
2. **§1 layout `<h1>`** — one line, un-reds ~14 assertions, makes everything else verifiable.
3. **§2 StatisticsService** (+ its test window) — un-reds the remaining 3 unit errors.
4. **§5, §4** — the two live data leaks.
5. **§6, §7** — silent data loss and the 500.
6. **§8 the Turbo collapse** — largest cleanup win, but do it *after* 1–3 so there's a green
   suite to verify against.

Security and data-loss before refactors; the Turbo rewrite last, when it can be verified.

---

## Status — what was fixed in this pass

| Suite | Before | After |
|---|---|---|
| `bin/rails test` | 26 runs, 4 errors | **48 runs, 0 failures, 0 errors** — reliably green, many runs |
| `bin/rails test:system` | 46 runs, 18 failures, 2 errors | **47 runs, 0 failures, 0 errors** when it completes cleanly — but see below |

**Honest caveat on the system suite.** It went from *deterministically* 18 failures + 2 errors
to *intermittently* one failure. Roughly half of full 47-test runs still hit a single Capybara
timeout somewhere in `UsersTest`; the same tests pass 4/4 in isolation. Every failure is a
timeout (`Unable to find field`, `Unable to find modal dialog`, a missing post-submit flash) —
never an assertion that disagrees about app behaviour, and never the same test twice running.
It does not track CPU load (reproduced at load 1.2), and the host had ~1.2GB free RAM with a
browser holding 11GB, so headless-Chrome memory pressure is the leading suspect. Mitigated by
waiting on navigation, removing order-dependent `match: :first` selectors, and raising
Capybara's wait to 10s. **Not fully resolved — worth re-checking on CI's dedicated runner.**

Fixed: §1 (layout heading), §2 (StatisticsService + its test window), §3 (seeded admin
credentials, seeds now idempotent), §4 (channel subscribe authorization, with tests that were
verified to fail against the unfixed code), §5 (JSON gating + per-ability cache key + the
lazy-relation cache), §6 (CSV import reporting), §7 (user destroy), §34 (result uniqueness
validation). Plus rubocop to zero, brakeman to zero, herb analyze/lint clean, and the dead
navbar dropdown removed with the active-page state restored.

**Two findings discovered during the fixing, not in the original review:**

### 🔴 Both hand-rolled `fetch` helpers crashed on a missing CSRF meta tag
`group_permissions_controller.js:16`, `scoring_controller.js:60` read
`document.querySelector('meta[name="csrf-token"]').content` unguarded. `csrf_meta_tags` renders
nothing when forgery protection is off, so the lookup returned `null` and the whole Stimulus
action died with a `TypeError` **before the request was sent** — silently, since neither caller
reports errors. Found by capturing browser console logs, not by reading. Fixed.

### 🟢 Password reset is unreachable from the UI
`app/views/devise/sessions/new.html.erb` had `<%#= render "devise/shared/links" %>` — the same
commented-out-ERB mistake as §1. Removing the dead tag preserves current behaviour, but it means
there is no "Forgot your password?" link anywhere. Worth a product decision, especially since
§22 recommends dropping `:registerable` (which is what that partial's "Sign up" link would
otherwise expose).

## Still red in CI — each needs its own pass

- **`bundler-audit`** — CVE advisories across ~21 gems (rails, rack, nokogiri, puma, devise,
  websocket-driver…). This is the [[dependency-upgrade]] pass; deliberately not touched here.
- **`database_consistency`** — 20 remaining findings: missing NOT NULL on `challenges`
  number/description/points/group_id and `settings.value`, missing length validators, redundant
  indexes, and a missing unique index on `challenges.number` (§34's other half). The NOT NULL
  ones are migrations on populated tables, so they need the multi-step nullable → backfill →
  constrain pattern rather than a single migration.

Everything else in `hk run check --all` is green: actionlint, zizmor, gitleaks, rubocop,
brakeman, herb-analyze, herb-lint, jscpd, debride, flay, fasterer, and the test suite.

## Not done — the largest remaining item

**§8, the Turbo collapse (~300 net lines).** Deferred by agreement: it rewrites the app's core
scoring path, and it was worth having a green suite to verify against first. That safety net now
exists, so it is a much safer change than it was this morning.
