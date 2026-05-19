# meteo

## Démarrage standard

Depuis la racine du projet :

```bash
make dev
make init
make up
make ps
make logs
```

Pour la production :

```bash
make prod
make check
make rebuild
make up
make ps
```

Séquence de mise à jour standard :

```bash
make prod
make update
```

### Règles

- `.env` doit être un lien symbolique vers `.env.dev` ou `.env.prod`
- `.env.local` contient les secrets et ne doit jamais être commité
- `make migrate` est un no-op pour cette application Node/Express
- `make backup` est un no-op car le projet ne gère pas de base locale

## Conteneurisation

### Developpement (local)

```bash
make dev
make up
make ps
make logs
```

Application: `http://localhost:3003` (ou la valeur `DEV_WEB_PORT` dans `.env.dev`).

### Production (Linode + Traefik)

```bash
make prod
make up
make ps
make logs
```

Mode attendu:
- `.env` est un lien symbolique vers `.env.dev` en developpement.
- `.env` est un lien symbolique vers `.env.prod` sur Linode.
- les secrets sont dans `.env.local` (non commite).

## Gestion des secrets (.env.local)

Le fichier `.env.local` reste local et ne doit pas etre commit.

### 1. Initialiser l'identité du projet

```bash
sed -n '1,40p' .env.template
make dev
make init
```

### 2. Recuperer les secrets depuis mdp.mon-site.ca

```bash
SECRETS_ACCESS_TOKEN="ton_token" npm --prefix app run secrets:pull -- --app meteo --env dev
```

Si ton API retourne un payload chiffre (ex: `ciphertext`/`iv`/`tag`), ajoute:

```bash
SECRETS_ENCRYPTION_KEY="ta_cle_locale" npm --prefix app run secrets:pull -- --app meteo --env dev
```

### Variables supportees par pull-secrets

- `SECRETS_URL` (URL complete de l'API, prioritaire)
- `SECRETS_BASE_URL` (defaut: `https://mdp.mon-site.ca`)
- `SECRETS_ENDPOINT` (defaut: `/api/secrets`)
- `SECRETS_ACCESS_TOKEN` (Bearer token)
- `SECRETS_ENCRYPTION_KEY` (si payload chiffre)
- `SECRETS_OUTPUT_FILE` (defaut: `.env.local`)
- `SECRETS_TEMPLATE_FILE` (defaut: `.env.example`)
- `SECRETS_APP` (defaut: `meteo`)
- `SECRETS_ENV` (defaut: `dev`)

Tu peux aussi utiliser le wrapper:

```bash
./scripts/pull-secrets.sh --app meteo --env dev
```

### Format API attendu

Le script accepte ces formats JSON:

1. Clair:

```json
{ "secrets": { "API_KEY": "xxx", "API_CITY": "montreal,ca" } }
```

2. Chiffre:

```json
{ "ciphertext": "...", "iv": "...", "tag": "...", "salt": "..." }
```

Dans tous les cas, le script:

- verifie les cles attendues de `.env.example`
- ecrit `.env.local` en mode restreint (`600`)
- n'affiche pas les valeurs secretes

Le token local `METEO_API_TOKEN` est généré automatiquement si nécessaire par :

```bash
./scripts/generate-secrets.sh
```

## Integration Dashboard

L'application `meteo` peut servir de source JSON pour `dashboard`.

Variables a definir dans `.env.local` :

```env
API_KEY=
METEO_API_TOKEN=
OPENWEATHER_API_TOKEN=
```

Regles :

- `API_KEY` est la cle fournisseur OpenWeather et reste uniquement cote `meteo` ;
- `METEO_API_TOKEN` est le nom canonique du token inter-apps utilise pour authentifier les appels backend du `dashboard` via l'en-tete `X-Internal-Api-Token` ;
- `OPENWEATHER_API_TOKEN` reste accepte temporairement comme alias de transition ;
- le `dashboard` ne doit jamais stocker `API_KEY`.

Endpoint expose pour le dashboard :

```text
GET /api/dashboard/weather/
```

Parametres optionnels :

- `q`
- `lat`
- `lon`
- `units`
- `lang`
