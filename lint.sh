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
done
