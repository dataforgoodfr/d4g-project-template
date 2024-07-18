from locust import HttpUser, between, task


class HomeTest(HttpUser):
    host = "https://carbonbombs-git-loadtesting-carbonbombs.vercel.app"

    headers = {
        "User-Agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/118.0",
        "Accept": "*/*",
        "Accept-Language": "fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3",
        "Accept-Encoding": "gzip, deflate, br",
        "Referer": "https://carbonbombs-git-loadtesting-carbonbombs.vercel.app/map",
        "Content-Type": "text/plain;charset=UTF-8",
        "Origin": "https://carbonbombs-git-loadtesting-carbonbombs.vercel.app",
        "Connection": "keep-alive",
        "Sec-Fetch-Dest": "empty",
        "Sec-Fetch-Mode": "cors",
        "Sec-Fetch-Site": "same-origin",
        "TE": "trailers",
    }

    # Set the time to wait between two requests for one user
    wait_time = between(1, 5)

    def on_start(self):
        """
        On start we clear the API cache
        """
        pass

    @task
    def index(self):
        self.client.get("/")

    @task
    def map(self):
        self.client.get("/map")
        payload = {
            "query": "MATCH (p:carbon_bomb) WITH collect(properties(p)) as bombs RETURN bombs"
        }
        with self.client.post(
            "/api/neo4j",
            json=payload,
            catch_response=True,
            headers=self.headers,
        ) as response:
            if response.status_code != 200:
                response.failure(
                    f"map - Response code not 200 : {response.status_code} {response}"
                )

    @task
    def filter_map(self):
        payload = {
            "query": 'MATCH (p:carbon_bomb)-[:OPERATES]-(c:company) WHERE c.name IN ["TotalEnergies SE"] WITH collect(properties(p)) as bombs RETURN bombs'
        }

        with self.client.post(
            "/api/neo4j",
            json=payload,
            catch_response=True,
            headers=self.headers,
        ) as response:
            if response.status_code != 200:
                response.failure(
                    f"filter_map - Response code not 200 : {response.status_code}"
                )
