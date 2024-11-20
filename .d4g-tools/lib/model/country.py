from sqlmodel import SQLModel, Field
from typing import Optional

class RegionBase(SQLModel):
    name: str

class Region(RegionBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)

class CountryBase(SQLModel):
    name: str
    iso_code: str
    region_id: int

class Country(CountryBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
