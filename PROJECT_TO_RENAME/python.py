import math
from typing import Union

selector_company: list[str] = []
selected_year: Union[str, None] = None
selector_year: list[str] = []
company_sector: Union[str, None] = None
company_upe_name: str = ""


def calculate_circumference(radius):
    circumference = 2 * math.pi * radius
    print(f"The circumference of the circle with radius {radius} is {circumference}")


calculate_circumference(10)
