Sure, here's a step-by-step guide to build the Flask web application as per your requirements:

### Step 1: Scrape Data and Store Locally

First, you'll need to scrape data from `data.gouv.fr` and store it locally as a CSV file.

```python
import requests
import pandas as pd

# Make a GET request to the website
url = 'https://www.data.gouv.fr/path_to_csv_file'
r = requests.get(url)

# Save the content in a pandas DataFrame
df = pd.read_csv(r.content)

# Save the DataFrame to a CSV file
df.to_csv('./data/initial/data.csv', index=False)
```

### Step 2: Create SQLModel and Persist to PostgreSQL

Next, create a SQLModel based on the CSV headers and persist it to PostgreSQL.

```python
from sqlmodel import SQLModel, Session, create_engine, Field
from typing import Optional
import pandas as pd

# Load the CSV file
df = pd.read_csv('./data/initial/data.csv')

# Define your SQLModel dynamically based on the CSV headers
class Data(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    for col in df.columns:
        exec(f"{col} = Field(None)")

# Create an engine and a session
engine = create_engine("postgresql://user:password@db/dbname")
SQLModel.metadata.create_all(engine)
session = Session(engine)

# Persist the data to PostgreSQL
for index, row in df.iterrows():
    data = Data(**row.to_dict())
    session.add(data)

session.commit()
```

### Step 3: Build Flask Web App

Now, build a Flask web app to display the data using Flask-Table for enhanced table components.

```python
from flask import Flask, render_template
from flask_table import Table, Col
from sqlmodel import select

# Declare your table
class DataTable(Table):
    id = Col('ID')
    for col in df.columns:
        exec(f"{col} = Col('{col}')")

app = Flask(__name__)

@app.route('/')
def index():
    result = session.exec(select(Data)).all()
    table = DataTable(result)
    return render_template('index.html', table=table)

if __name__ == '__main__':
    app.run(debug=True)
```

### Step 4: Dockerize the Application

Create a `Dockerfile` for the Flask application:

```Dockerfile
FROM python:3.8-slim

WORKDIR /app

COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

COPY . .

ENTRYPOINT ["./entrypoint.sh"]
```

Create an `entrypoint.sh` script:

```sh
#!/bin/sh

# Wait for PostgreSQL to be ready
while ! nc -z db 5432; do
  sleep 1
done

# Run the application
exec "$@"
```

Make sure to give execute permission to `entrypoint.sh`:

```sh
chmod +x entrypoint.sh
```

Create a `docker-compose.yml` file:

```yaml
version: '3'
services:
  web:
    build: .
    command: gunicorn -w 4 -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:5000
    ports:
      - "5000:5000"
    depends_on:
      - db
  db:
    image: "postgres"
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: dbname
```

Create a `requirements.txt` file:

```
Flask
Flask-Table
pandas
requests
sqlmodel
psycopg2-binary
gunicorn
uvicorn
```

### Step 5: Build and Run the Application

Build and run the Docker containers:

```sh
docker compose up --build
```

This will build the Docker images and start the containers. You can access the Flask web app at `http://localhost:5000`.

Feel free to adjust the code to fit your specific needs and ensure that all dependencies are installed correctly.
