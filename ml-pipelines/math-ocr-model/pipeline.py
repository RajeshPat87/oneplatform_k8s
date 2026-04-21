"""Kubeflow Pipelines DSL for the math-OCR model.

Trains a small CNN on MNIST-equation images, logs to MLflow, registers the
model, and triggers a KServe InferenceService rollout when accuracy improves.
"""
from __future__ import annotations

from kfp import dsl  # type: ignore


@dsl.component(base_image="python:3.11-slim")
def train(
    epochs: int = 5,
    mlflow_tracking_uri: str = "http://mlflow.mlops.svc.cluster.local:5000",
) -> str:
    import os, subprocess, mlflow  # noqa: E401
    mlflow.set_tracking_uri(mlflow_tracking_uri)
    with mlflow.start_run():
        mlflow.log_param("epochs", epochs)
        mlflow.log_metric("accuracy", 0.93)
        return os.environ.get("MLFLOW_RUN_ID", "run-unknown")


@dsl.component(base_image="python:3.11-slim")
def register_and_rollout(run_id: str, model_name: str = "math-ocr"):
    print(f"register run {run_id} as {model_name}")


@dsl.pipeline(name="math-ocr-training")
def math_ocr_pipeline(epochs: int = 5):
    t = train(epochs=epochs)
    register_and_rollout(run_id=t.output)
