#!/usr/bin/env bash
# Sync hardware-configuration.nix → hardware-configuration.nix.example
# Replaces UUIDs and paths with placeholders

set -euo pipefail

NIX_FILE="${1:?Usage: $0 <path-to-hardware-configuration.nix>}"
EXAMPLE_FILE="${NIX_FILE}.example"

if [[ ! -f "$NIX_FILE" ]]; then
  echo "Error: $NIX_FILE not found" >&2
  exit 1
fi

cp "$NIX_FILE" "$EXAMPLE_FILE"

# Replace disk UUIDs with REPLACE-ME
sed -i 's|/dev/disk/by-uuid/[A-Za-z0-9-]*|/dev/disk/by-uuid/REPLACE-ME|g' "$EXAMPLE_FILE"

echo "Synced: $EXAMPLE_FILE"