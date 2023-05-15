#!/usr/bin/env bash

set -euo pipefail

for f in *.yaml; do
  echo "---" "$f"

  # Check that every package name is listed in packages.txt
  want=$(yq '.package.name' "$f")
  if ! grep -q "$want" packages.txt; then
    echo "missing $want in packages.txt"
    exit 1
  fi

  # With the introduction of https://github.com/chainguard-dev/enterprise-advisories,
  # package config files should no longer contain any advisory data.
  if [[ "$(yq 'keys | contains(["advisories"])' "$f")" == "true" ]]; then
    echo "
$f has an 'advisories' section, but advisory data should now be stored in https://github.com/chainguard-dev/enterprise-advisories.

To learn about how to create advisory data in the advisories repo, run 'wolfictl advisory create -h', and check out the '--advisories-repo-dir' flag."
    exit 1
  fi
done
