#!/usr/bin/env bash
set -euo pipefail

./scripts/check-invariants.sh

echo "OK: aucune base locale à sauvegarder pour meteo"
