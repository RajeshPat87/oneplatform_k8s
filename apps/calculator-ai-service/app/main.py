from __future__ import annotations

import logging
import os
from dataclasses import asdict

from fastapi import FastAPI, HTTPException
from prometheus_fastapi_instrumentator import Instrumentator
from pydantic import BaseModel, Field

from app.solver import solve

logging.basicConfig(level=os.environ.get("LOG_LEVEL", "INFO"))
log = logging.getLogger("calculator-ai-service")

app = FastAPI(title="Calculator AI Service", version="0.1.0")
Instrumentator().instrument(app).expose(app, endpoint="/metrics")


class SolveRequest(BaseModel):
    question: str = Field(min_length=1, max_length=1000)


@app.get("/healthz")
def healthz() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/readyz")
def readyz() -> dict[str, str]:
    return {"status": "ready"}


@app.post("/solve")
async def post_solve(payload: SolveRequest):
    try:
        result = await solve(payload.question)
    except Exception as e:
        log.exception("solver failed")
        raise HTTPException(status_code=502, detail=f"AI backend error: {e}") from e
    return asdict(result)
