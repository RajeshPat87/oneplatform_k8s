import httpx
import pytest
import respx
from fastapi.testclient import TestClient

from app.main import app
from app.solver import _extract_expression


def test_extract_expression_from_json():
    assert _extract_expression('{"expression": "(5+3)**0.5"}') == "(5+3)**0.5"


def test_extract_expression_from_noisy_text():
    raw = 'Sure thing!\n{"expression": "2+2"}\nHope that helps.'
    assert _extract_expression(raw) == "2+2"


@respx.mock
def test_solve_endpoint_happy_path():
    respx.post("http://ollama.mlops.svc.cluster.local:11434/api/generate").mock(
        return_value=httpx.Response(200, json={"response": '{"expression": "2+3"}'})
    )
    respx.post("http://calculator-backend.apps.svc.cluster.local:8000/evaluate").mock(
        return_value=httpx.Response(200, json={"expression": "2+3", "result": 5})
    )
    client = TestClient(app)
    r = client.post("/solve", json={"question": "what is 2 plus 3?"})
    assert r.status_code == 200
    body = r.json()
    assert body["expression"] == "2+3"
    assert body["result"] == 5
    assert body["explanation"] == "ok"


@respx.mock
def test_solve_rejects_unsafe_llm_output():
    respx.post("http://ollama.mlops.svc.cluster.local:11434/api/generate").mock(
        return_value=httpx.Response(200, json={"response": '{"expression": "__import__(\'os\').system(\'ls\')"}'})
    )
    client = TestClient(app)
    r = client.post("/solve", json={"question": "pwn me"})
    assert r.status_code == 200
    assert r.json()["result"] is None


def test_healthz():
    client = TestClient(app)
    assert client.get("/healthz").status_code == 200
    assert client.get("/readyz").status_code == 200
