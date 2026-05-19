#!/usr/bin/env bash
set -euo pipefail

ENV_LOCAL=".env.local"

[ -f "$ENV_LOCAL" ] || {
  echo "Erreur: .env.local introuvable."
  exit 1
}

generate_secret() {
  openssl rand -base64 48 | tr -d '\n'
}

read_value() {
  local key="$1"
  sed -n "s/^${key}=//p" "$ENV_LOCAL" | tail -n 1
}

set_value_if_empty() {
  local key="$1"
  local value="$2"

  if grep -q "^${key}=$" "$ENV_LOCAL"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$ENV_LOCAL"
  elif ! grep -q "^${key}=" "$ENV_LOCAL"; then
    echo "${key}=${value}" >> "$ENV_LOCAL"
  fi
}

set_value_if_empty "METEO_API_TOKEN" "$(generate_secret)"

METEO_API_TOKEN_VALUE="$(read_value METEO_API_TOKEN)"
if [ -n "$METEO_API_TOKEN_VALUE" ]; then
  set_value_if_empty "OPENWEATHER_API_TOKEN" "$METEO_API_TOKEN_VALUE"
fi

echo "Secrets générés dans .env.local"
echo "API_KEY reste à renseigner manuellement."
echo "OPENWEATHER_API_TOKEN reste aligné sur METEO_API_TOKEN tant que l'alias transitoire est conservé."
