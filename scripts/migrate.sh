#!/usr/bin/env bash
set -euo pipefail

./scripts/check-invariants.sh

echo "OK: aucune migration à appliquer pour meteo"
