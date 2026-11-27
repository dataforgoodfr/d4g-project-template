from pathlib import Path

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

app = FastAPI(docs_url="/api/docs", openapi_url="/api/openapi.json")


@app.get("/api/health")
def health():
    return {"status": "ok"}


static = Path(__file__).parent / "static"
if static.is_dir():
    app.mount("/", StaticFiles(directory=static, html=True), name="static")
