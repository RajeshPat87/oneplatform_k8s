from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_healthz():
    r = client.get("/healthz")
    assert r.status_code == 200 and r.json()["status"] == "ok"


def test_readyz():
    r = client.get("/readyz")
    assert r.status_code == 200


def test_evaluate_ok():
    r = client.post("/evaluate", json={"expression": "2+3*4"})
    assert r.status_code == 200
    assert r.json() == {"expression": "2+3*4", "result": 14}


def test_evaluate_rejects_unsafe():
    r = client.post("/evaluate", json={"expression": "__import__('os').system('ls')"})
    assert r.status_code == 400


def test_evaluate_validates_length():
    r = client.post("/evaluate", json={"expression": ""})
    assert r.status_code == 422
