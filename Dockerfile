FROM node:26-alpine@sha256:6bd9ab43c0ec0190ca7b2d193906cb8b7edf6e7f4afa43ddeccd6452710bffb5 AS frontend
WORKDIR /app
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/ ./
CMD ["npm", "run", "dev", "--", "--hostname", "0.0.0.0"]

FROM frontend AS frontend-build
RUN npm run build

FROM python:3.14-slim@sha256:22eafb370920ad8b429e0aec3fff433e0669968519f5d60469d83729c138b28b AS backend
COPY --from=ghcr.io/astral-sh/uv:0.13.10@sha256:a3ea1357342c1a4bf9a0c53a3deb1b55379aefa037338d8113d5771efa01774f /uv /bin/uv
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_NO_DEV=1 \
    UV_PYTHON_DOWNLOADS=0 \
    PATH="/app/.venv/bin:$PATH"
WORKDIR /app
COPY backend/pyproject.toml backend/uv.lock ./
RUN uv sync --locked --no-install-project
COPY backend/ ./
CMD ["fastapi", "dev", "main.py", "--host", "0.0.0.0"]

FROM python:3.14-slim@sha256:22eafb370920ad8b429e0aec3fff433e0669968519f5d60469d83729c138b28b
ENV PATH="/app/.venv/bin:$PATH"
WORKDIR /app
COPY --from=backend /app ./
COPY --from=frontend-build /app/out ./static
USER 65534
EXPOSE 8080
CMD ["fastapi", "run", "main.py", "--port", "8080"]
