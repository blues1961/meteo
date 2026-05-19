#!/usr/bin/env bash
set -euo pipefail

TEMPLATE=".env.template"

[ -f "$TEMPLATE" ] || {
  echo "ERREUR: .env.template manquant"
  exit 1
}

load_template() {
  local file="$1"
  local line key value

  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      ''|\#*)
        continue
        ;;
    esac

    key=${line%%=*}
    value=${line#*=}
    key=$(printf '%s' "$key" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    value=$(printf '%s' "$value" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

    if [ -n "$key" ]; then
      printf -v "$key" '%s' "$value"
      export "$key"
    fi
  done < "$file"
}

ensure_local_key() {
  local key="$1"

  if ! grep -q "^${key}=" .env.local; then
    printf '%s=\n' "$key" >> .env.local
    echo "• .env.local complété avec ${key}"
  fi
}

load_template "$TEMPLATE"

[ -n "${APP_NAME:-}" ] || { echo "APP_NAME manquant"; exit 1; }
[ -n "${APP_SLUG:-}" ] || { echo "APP_SLUG manquant"; exit 1; }
[ -n "${APP_DEPOT:-}" ] || { echo "APP_DEPOT manquant"; exit 1; }
[ -n "${APP_NO:-}" ] || { echo "APP_NO manquant"; exit 1; }

APP_HOST_TEMPLATE="${APP_HOST:-${APP_SLUG}.mon-site.ca}"
API_CITY_VALUE="${API_CITY:-saint-jean-de-matha,ca}"
API_UNITS_VALUE="${API_UNITS:-metric}"
API_LANGUE_VALUE="${API_LANGUE:-fr}"
CURRENT_BASE_URL_VALUE="${CURRENT_BASE_URL:-http://api.openweathermap.org/data/2.5/weather}"
FORECAST_BASE_URL_VALUE="${FORECAST_BASE_URL:-http://api.openweathermap.org/data/2.5/forecast}"

DEV_WEB_PORT=$((3000 + APP_NO))

cat > .env.dev <<EOF
APP_ENV=dev
APP_NAME=$APP_NAME
APP_SLUG=$APP_SLUG
APP_DEPOT=$APP_DEPOT
APP_NO=$APP_NO
APP_HOST=localhost
DEV_WEB_PORT=$DEV_WEB_PORT
NODE_ENV=development
PORT=3000
API_CITY=$API_CITY_VALUE
API_UNITS=$API_UNITS_VALUE
API_LANGUE=$API_LANGUE_VALUE
CURRENT_BASE_URL=$CURRENT_BASE_URL_VALUE
FORECAST_BASE_URL=$FORECAST_BASE_URL_VALUE
EOF

echo "✔ .env.dev généré"

cat > .env.prod <<EOF
APP_ENV=prod
APP_NAME=$APP_NAME
APP_SLUG=$APP_SLUG
APP_DEPOT=$APP_DEPOT
APP_NO=$APP_NO
APP_HOST=$APP_HOST_TEMPLATE
NODE_ENV=production
PORT=3000
API_CITY=$API_CITY_VALUE
API_UNITS=$API_UNITS_VALUE
API_LANGUE=$API_LANGUE_VALUE
CURRENT_BASE_URL=$CURRENT_BASE_URL_VALUE
FORECAST_BASE_URL=$FORECAST_BASE_URL_VALUE
EOF

echo "✔ .env.prod généré"

if [ ! -f ".env.local" ]; then
cat > .env.local <<EOF
API_KEY=
METEO_API_TOKEN=
OPENWEATHER_API_TOKEN=
EOF
  echo "✔ .env.local créé"
else
  echo "• .env.local existe déjà (non modifié)"
fi

ensure_local_key "API_KEY"
ensure_local_key "METEO_API_TOKEN"
ensure_local_key "OPENWEATHER_API_TOKEN"

./scripts/generate-secrets.sh

echo "✔ Environnement complet prêt"
