#!/usr/bin/env bash
# Assert that every place a toolchain or service version is pinned agrees.
#
# These versions are spelled out in several files because different consumers read
# different ones: mise.toml drives local dev, .ruby-version/.node-version feed CI's
# setup-ruby/setup-node, and the Dockerfile ARGs build the production image. Nothing
# makes them agree on its own, so a bump that misses one file silently ships an image
# built on a different Ruby than the one the tests ran against.
#
# Run by the hk `versions` step and by CI's `versions` job, so local and CI agree.
# Adapted from the equivalent check in the BlackLightning repo.

set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

fail=0
note() {
  echo "  ✗ $1"
  fail=1
}

# .ruby-version may be written bare (3.4.10) or prefixed (ruby-3.4.10); both are valid
# for setup-ruby and mise, so normalise before comparing.
ruby_file=$(tr -d '[:space:]' < .ruby-version | sed 's/^ruby-//')
node_file=$(tr -d '[:space:]' < .node-version)

read_mise() { sed -n "s/^$1[[:space:]]*=[[:space:]]*\"\([^\"]*\)\".*/\1/p" mise.toml; }
read_arg()  { sed -n "s/^ARG $1=//p" Dockerfile | tr -d '[:space:]'; }

ruby_mise=$(read_mise ruby)
node_mise=$(read_mise node)
yarn_mise=$(read_mise yarn)

ruby_docker=$(read_arg RUBY_VERSION)
node_docker=$(read_arg NODE_VERSION)
yarn_docker=$(read_arg YARN_VERSION)

echo "Toolchain:"
[ -n "$ruby_file" ] && [ -n "$ruby_mise" ] && [ -n "$ruby_docker" ] ||
  note "could not read a ruby version from all of .ruby-version, mise.toml, Dockerfile"
[ "$ruby_file" = "$ruby_mise" ] ||
  note "mise.toml ruby ($ruby_mise) != .ruby-version ($ruby_file)"
[ "$ruby_file" = "$ruby_docker" ] ||
  note "Dockerfile ARG RUBY_VERSION ($ruby_docker) != .ruby-version ($ruby_file)"

[ -n "$node_file" ] && [ -n "$node_mise" ] && [ -n "$node_docker" ] ||
  note "could not read a node version from all of .node-version, mise.toml, Dockerfile"
[ "$node_file" = "$node_mise" ] ||
  note "mise.toml node ($node_mise) != .node-version ($node_file)"
[ "$node_file" = "$node_docker" ] ||
  note "Dockerfile ARG NODE_VERSION ($node_docker) != .node-version ($node_file)"

[ -n "$yarn_mise" ] && [ -n "$yarn_docker" ] ||
  note "could not read a yarn version from both mise.toml and Dockerfile"
[ "$yarn_mise" = "$yarn_docker" ] ||
  note "Dockerfile ARG YARN_VERSION ($yarn_docker) != mise.toml yarn ($yarn_mise)"

[ "$fail" -eq 0 ] && echo "  ✓ ruby $ruby_file · node $node_file · yarn $yarn_mise"

# MySQL: CI has to exercise the server production actually runs, or the suite is
# green against a database nobody deploys. Tags may carry a digest (image: mysql:8.4@sha256:…),
# so match only the tag.
mysql_pat='s/^[[:space:]]*image:[[:space:]]*"\?mysql:\([0-9][0-9.]*\).*/\1/p'
mysql_prod=$(sed -n "$mysql_pat" docker-compose.yml)
mysql_ci=$(sed -n "$mysql_pat" .github/workflows/ci.yml)

echo "MySQL:"
if [ -z "$mysql_prod" ] || [ -z "$mysql_ci" ]; then
  note "could not read a mysql version from both docker-compose.yml and .github/workflows/ci.yml"
elif [ "$mysql_prod" != "$mysql_ci" ]; then
  note "ci.yml mysql ($mysql_ci) != docker-compose.yml ($mysql_prod) — CI must test the server production runs"
else
  echo "  ✓ mysql $mysql_prod in both docker-compose.yml and CI"
fi

exit "$fail"
