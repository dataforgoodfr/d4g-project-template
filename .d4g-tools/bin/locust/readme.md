# Tests de charge

Pour vérifier le bon fonctionnement du site avec plusieurs utilisateurs des tests de charge ont été mis en place, à l'aide de [Locust](https://locust.io/), un outil de test de charge.

<!-- Installation :
```shell
cd load_testing
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
``` -->

Lancement :
```shell
cd load_testing
source .venv/bin/activate
locust -f load_testing.py
```

Puis se rendre à l'adresse http://0.0.0.0:8089 pour lancer un test avec le nombre d'utilisateurs souhaités.

