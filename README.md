# Template Data For Good

Point de départ pour les projets Data For Good : un front Next.js, une API FastAPI (optionnelle), une image Docker prête pour Clever Cloud, et une CI qui s'appuie sur les workflows communs de [d4g-ci](https://github.com/dataforgoodfr/d4g-ci).

La stack reprend ce que la plupart des projets des dernières saisons ont fini par choisir. Si votre projet a d'autres besoins, rien n'empêche de partir sur autre chose.

## Ce qu'il y a dedans

```
frontend/   Next.js (TypeScript, Tailwind), exporté en site statique
backend/    FastAPI, géré avec uv
Dockerfile  construit le front, puis une image Python qui sert l'API et le site
```

En production, tout tourne dans un seul conteneur : FastAPI répond sous `/api` et sert les pages du front pour le reste. Une seule application à déployer, une seule à payer.

## Démarrer

Le plus simple, avec Docker :

```bash
docker compose up --watch
```

Le site est sur http://localhost:3000 et la doc de l'API sur http://localhost:3000/api/docs. Les modifications dans `frontend/` et `backend/` sont prises en compte à chaud. Après un changement de dépendances (`uv.lock` ou `package-lock.json`), l'image concernée est reconstruite toute seule.

Sans Docker, il faut [uv](https://docs.astral.sh/uv/) et Node.js (la version est dans le champ `engines` de `frontend/package.json`). Dans un premier terminal, l'API :

```bash
cd backend
uv sync
uv run fastapi dev main.py
```

Dans un second, le front :

```bash
cd frontend
npm install
npm run dev
```

Dans les deux cas, Next.js renvoie les appels `/api/...` vers FastAPI pendant le dev : le front appelle toujours `/api/...`, en local comme en prod.

Pour tester l'image comme en prod :

```bash
docker build -t mon-projet .
docker run --rm -p 8080:8080 mon-projet
```

Et pour installer les hooks pre-commit :

```bash
uvx pre-commit install
```

## Pas besoin d'API ?

Si les données peuvent être préparées à l'avance (fichiers JSON, Parquet, PMTiles...), le front peut s'en passer :

1. supprimer `backend/`, le job `backend` dans `.github/workflows/ci.yml` et le service `backend` dans `compose.yaml` (avec le `depends_on` du front)
2. retirer la partie Python du `Dockerfile`, ou déployer le dossier `frontend/out` comme site statique (Clever Cloud ou GitHub Pages)

## Le front en site statique

`next build` produit des fichiers statiques dans `frontend/out`. C'est suffisant pour la grande majorité des sites de visualisation, mais certaines fonctions de Next.js ne sont pas disponibles : rendu côté serveur, routes API, middleware, server actions. La logique côté serveur va dans FastAPI.

Si le projet a vraiment besoin de comptes utilisateurs, d'un CMS ou de rendu côté serveur, il faut passer Next.js en mode serveur (`output: "standalone"`) et le déployer comme une application à part.

## Données

- [DuckDB](https://duckdb.org/) couvre la plupart des besoins : pas de serveur à gérer, et il lit directement du Parquet ou du CSV, en local comme sur S3 (Cellar chez Clever Cloud).
- Pour des données saisies à la main par l'équipe ou l'association, Data For Good a une instance NocoDB partagée. L'API ou le pipeline peut la lire avec un token.
- Pour un vrai back-office de saisie et de validation, Django et son admin restent une bonne option.

Pour les cartes, la plupart des projets utilisent [MapLibre](https://maplibre.org/), souvent avec des tuiles PMTiles.

## CI

`.github/workflows/ci.yml` appelle les workflows de d4g-ci : pre-commit, tests et lint de l'API, lint et build du front, build de l'image Docker. Les paramètres de chaque workflow sont décrits dans le README de d4g-ci.

Dependabot met à jour chaque semaine les dépendances Python, npm, Docker et GitHub Actions.

## Déployer sur Clever Cloud

1. Créer une application Docker sur Clever Cloud.
2. Dans *Settings > Environments* du dépôt GitHub, créer un environnement `prod` avec la variable `CLEVER_APP_ID` et les secrets `CLEVER_TOKEN` et `CLEVER_SECRET`.
3. Dans *Settings > Secrets and variables > Actions*, ajouter la variable de dépôt `DEPLOY` à `true`.

Chaque push sur `main` déploie alors l'application, une fois la CI passée. Tant que `DEPLOY` n'est pas défini, le déploiement est simplement ignoré.

Pour plusieurs environnements (`dev`, `staging`, `prod`...), voir le README de d4g-ci.
