# syntax=docker/dockerfile:1.7
FROM python:3.12-slim AS base
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1
WORKDIR /app

FROM base AS deps
COPY pyproject.toml ./
RUN pip install --upgrade pip && pip install fastapi==0.115.0 "uvicorn[standard]==0.30.6" pydantic==2.9.2 prometheus-fastapi-instrumentator==7.0.0

FROM deps AS runtime
RUN useradd -u 10001 -r -s /usr/sbin/nologin app
COPY app ./app
USER 10001
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s CMD python -c "import urllib.request;urllib.request.urlopen('http://localhost:8000/healthz').read()" || exit 1
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
