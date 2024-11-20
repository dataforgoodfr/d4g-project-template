from fastapi import FastAPI, Depends
from sqlmodel import Session, SQLModel, create_engine
from sqlalchemy.orm import Session as SQLAlchemySession
import requests

DATABASE_URL = "postgresql://user:password@localhost/database"

engine = create_engine(DATABASE_URL)

def get_db() -> SQLAlchemySession:
    with Session(engine) as session:
        yield session

app = FastAPI()

@app.on_event("startup")
def on_startup():
    with Session(engine) as session:
        SQLModel.metadata.create_all(engine)
        # Fetch data from Gapminder API
        response = requests.get("https://api.gapminder.org/iso_codes")
        data = response.json()
        for item in data:
            country = Country(name=item["name"], iso_code=item["iso_code"], region_id=item["region_id"])
            session.add(country)
        session.commit()

country_route = BaseRoute(Country, get_db)
app.include_router(country_route.router, prefix="/countries", tags=["countries"])
