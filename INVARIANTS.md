# Invariants Meteo

## Environnement

Le projet utilise :

```text
.env.template
.env.dev
.env.prod
.env.local
.env
```

Règles :

- `.env` doit être un lien symbolique vers `.env.dev` ou `.env.prod`
- `.env.local` contient les secrets et ne doit jamais être commité
- `APP_NAME`, `APP_SLUG`, `APP_DEPOT`, `APP_NO` et `APP_ENV` doivent être définis

## Identité

Valeurs canoniques :

```env
APP_NAME=Meteo
APP_SLUG=meteo
APP_DEPOT=meteo
APP_NO=3
```

## Ports

Pour cette application Node/Express :

```env
DEV_WEB_PORT=3000 + APP_NO
```

Avec `APP_NO=3` :

```env
DEV_WEB_PORT=3003
```

## Secrets

Secrets attendus dans `.env.local` :

```env
API_KEY=
METEO_API_TOKEN=
OPENWEATHER_API_TOKEN=
```

Compatibilité transitoire :

- `METEO_API_TOKEN` est le nom canonique
- `OPENWEATHER_API_TOKEN` reste accepté temporairement comme alias
