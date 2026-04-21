"""FastAPI entrypoint for calculator-backend."""
from __future__ import annotations

import logging
import os

from fastapi import FastAPI, HTTPException
from prometheus_fastapi_instrumentator import Instrumentator
from pydantic import BaseModel, Field

from app.math_engine import UnsafeExpressionError, evaluate

logging.basicConfig(level=os.environ.get("LOG_LEVEL", "INFO"))
log = logging.getLogger("calculator-backend")

app = FastAPI(title="Calculator Backend", version="0.1.0")
Instrumentator().instrument(app).expose(app, endpoint="/metrics")


class EvalRequest(BaseModel):
    expression: str = Field(min_length=1, max_length=256)


class EvalResponse(BaseModel):
    expression: str
    result: float


@app.get("/healthz")
def healthz() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/readyz")
def readyz() -> dict[str, str]:
    return {"status": "ready"}


@app.post("/evaluate", response_model=EvalResponse)
def post_evaluate(payload: EvalRequest) -> EvalResponse:
    try:
        value = evaluate(payload.expression)
    except UnsafeExpressionError as e:
        log.info("rejected expression: %s", e)
        raise HTTPException(status_code=400, detail=str(e)) from e
    return EvalResponse(expression=payload.expression, result=value)
