"""Thin async client for Ollama / KServe compatible endpoints."""
from __future__ import annotations

import os
import httpx

OLLAMA_HOST = os.environ.get("OLLAMA_HOST", "http://ollama.mlops.svc.cluster.local:11434")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "llama3.1:8b")
LLM_TIMEOUT = float(os.environ.get("LLM_TIMEOUT_S", "30"))


async def ollama_generate(prompt: str) -> str:
    payload = {"model": OLLAMA_MODEL, "prompt": prompt, "stream": False}
    async with httpx.AsyncClient(timeout=LLM_TIMEOUT) as client:
        r = await client.post(f"{OLLAMA_HOST}/api/generate", json=payload)
        r.raise_for_status()
        return r.json().get("response", "").strip()
