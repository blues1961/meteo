#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "ERREUR: $1"
  exit 1
}

[ -f "INVARIANTS.md" ] || fail "INVARIANTS.md est manquant"
[ -f ".env.template" ] || fail ".env.template est manquant"
[ -f ".env.dev" ] || fail ".env.dev est manquant"
[ -f ".env.prod" ] || fail ".env.prod est manquant"
[ -f ".env.local" ] || fail ".env.local est manquant"
[ -L ".env" ] || fail ".env doit être un lien symbolique vers .env.dev ou .env.prod"

TARGET="$(readlink .env)"

if [ "$TARGET" != ".env.dev" ] && [ "$TARGET" != ".env.prod" ]; then
  fail ".env doit pointer vers .env.dev ou .env.prod"
fi

set -a
source .env
set +a

[ -n "${APP_NAME:-}" ] || fail "APP_NAME est manquant"
[ -n "${APP_SLUG:-}" ] || fail "APP_SLUG est manquant"
[ -n "${APP_DEPOT:-}" ] || fail "APP_DEPOT est manquant"
[ -n "${APP_NO:-}" ] || fail "APP_NO est manquant"
[ -n "${APP_ENV:-}" ] || fail "APP_ENV est manquant"
[ -n "${APP_HOST:-}" ] || fail "APP_HOST est manquant"

[ "$APP_ENV" = "dev" ] || [ "$APP_ENV" = "prod" ] || fail "APP_ENV doit être dev ou prod"

EXPECTED_WEB_PORT=$((3000 + APP_NO))
if [ "$APP_ENV" = "dev" ]; then
  [ "${DEV_WEB_PORT:-}" = "$EXPECTED_WEB_PORT" ] || fail "DEV_WEB_PORT devrait être $EXPECTED_WEB_PORT"
  [ "${NODE_ENV:-}" = "development" ] || fail "NODE_ENV devrait être development en dev"
fi

if [ "$APP_ENV" = "prod" ]; then
  [ "${NODE_ENV:-}" = "production" ] || fail "NODE_ENV devrait être production en prod"
fi

[ -f "docker-compose.${APP_ENV}.yml" ] || fail "docker-compose.${APP_ENV}.yml est manquant"

grep -q "^\.env$" .gitignore 2>/dev/null || fail ".gitignore doit ignorer .env"
grep -q "^\.env.local$" .gitignore 2>/dev/null || fail ".gitignore doit ignorer .env.local"

echo "OK: invariants valides pour APP_ENV=$APP_ENV"
