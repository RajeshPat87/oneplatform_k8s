"""Turn natural-language word problems into a safe arithmetic expression via LLM,
then evaluate it by delegating to the calculator-backend service."""
from __future__ import annotations

import json
import os
import re
from dataclasses import dataclass

import httpx

from app.llm_client import ollama_generate

BACKEND_URL = os.environ.get("BACKEND_URL", "http://calculator-backend.apps.svc.cluster.local:8000")

PROMPT_TEMPLATE = """You translate natural-language math word problems into a single
arithmetic expression using only digits, parentheses, and +, -, *, /, **, %.
Do NOT invoke functions or names. Reply with JSON: {{"expression": "<expr>"}}.

Problem: {question}
"""

SAFE_EXPR_RE = re.compile(r"^[0-9+\-*/().%\s]+$")


@dataclass
class SolverResult:
    question: str
    expression: str
    result: float | None
    explanation: str


def _extract_expression(raw: str) -> str:
    match = re.search(r"\{.*\}", raw, re.DOTALL)
    if match:
        try:
            data = json.loads(match.group(0))
            expr = str(data.get("expression", "")).strip()
            if expr:
                return expr
        except json.JSONDecodeError:
            pass
    line = raw.strip().splitlines()[0] if raw.strip() else ""
    return line.strip()


async def solve(question: str) -> SolverResult:
    prompt = PROMPT_TEMPLATE.format(question=question)
    raw = await ollama_generate(prompt)
    expression = _extract_expression(raw)
    if not expression or not SAFE_EXPR_RE.match(expression):
        return SolverResult(question=question, expression=expression, result=None,
                            explanation="LLM did not produce a safe expression.")
    async with httpx.AsyncClient(timeout=10.0) as client:
        r = await client.post(f"{BACKEND_URL}/evaluate", json={"expression": expression})
        if r.status_code != 200:
            return SolverResult(question=question, expression=expression, result=None,
                                explanation=f"Backend rejected: {r.text}")
        return SolverResult(question=question, expression=expression,
                            result=r.json()["result"], explanation="ok")
