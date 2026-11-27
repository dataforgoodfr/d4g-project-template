# Template Data For Good

Point de départ pour les projets Data For Good : un front Next.js, une API FastAPI (optionnelle), une image Docker prête pour Clever Cloud et une CI qui appelle [d4g-ci](https://github.com/dataforgoodfr/d4g-ci).

```
frontend/   Next.js (TypeScript, Tailwind), exporté en site statique
backend/    FastAPI, géré avec uv
Dockerfile  une seule image : FastAPI sert l'API sous /api et le site pour le reste
```

## Démarrer

```bash
docker compose up=
```

Le site est sur http://localhost:3000, la doc de l'API sur http://localhost:3000/api/docs.


Hooks pre-commit : `uvx pre-commit install`.

## Pas besoin d'API ?

Supprimer `backend/`, le job `backend` de `.github/workflows/ci.yml`, le service `backend` de `compose.yaml` et la partie Python du `Dockerfile`. Le dossier `frontend/out` peut aussi être déployé comme site statique.

## Déployer sur Clever Cloud

1. Créer une application Docker sur Clever Cloud.
2. Dans *Settings > Environments*, créer un environnement `prod` avec la variable `CLEVER_APP_ID` et les secrets `CLEVER_TOKEN` et `CLEVER_SECRET`.
3. Dans *Settings > Secrets and variables > Actions*, ajouter la variable `DEPLOY` à `true`.

Chaque push sur `main` déploie alors l'application une fois la CI passée.
