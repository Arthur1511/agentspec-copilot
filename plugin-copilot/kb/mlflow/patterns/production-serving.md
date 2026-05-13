# Production Serving Pattern

## Purpose

Patterns for serving MLflow-registered models in production: REST API via `mlflow models serve`, FastAPI wrapper, and batch inference pipelines.

---

## Option 1 — MLflow Built-in REST Server

```bash
# Serve registered model (Production stage)
mlflow models serve \
  --model-uri "models:/fraud-classifier/Production" \
  --host 0.0.0.0 --port 8080 \
  --env-manager conda          # or 'virtualenv' or 'local'

# Serve from run artifact
mlflow models serve \
  --model-uri "runs:/abc123/model" \
  --port 8080 --env-manager local
```

```bash
# Test the server
curl -X POST http://localhost:8080/invocations \
  -H "Content-Type: application/json" \
  -d '{"dataframe_records": [{"feature_1": 1.2, "feature_2": 0.5}]}'
```

---

## Option 2 — FastAPI Wrapper (Recommended for Production)

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
import mlflow
import mlflow.sklearn
import numpy as np
import pandas as pd
from typing import Any
import logging

logger = logging.getLogger(__name__)

# ── Schema ────────────────────────────────────────────────────────────
class PredictRequest(BaseModel):
    records: list[dict[str, Any]] = Field(..., min_length=1, max_length=1000,
                                           description="List of feature dicts")

class PredictResponse(BaseModel):
    predictions: list[int | float]
    probabilities: list[float] | None = None
    model_version: str
    model_name: str

# ── App ───────────────────────────────────────────────────────────────
app = FastAPI(title="ML Model Server", version="1.0.0")

MODEL_NAME = "fraud-classifier"
MODEL_STAGE = "Production"
_model = None
_model_version = None

def load_model():
    global _model, _model_version
    client = mlflow.MlflowClient()
    versions = client.get_latest_versions(MODEL_NAME, stages=[MODEL_STAGE])
    if not versions:
        raise RuntimeError(f"No {MODEL_STAGE} version for {MODEL_NAME}")
    _model_version = versions[0].version
    _model = mlflow.sklearn.load_model(f"models:/{MODEL_NAME}/{MODEL_STAGE}")
    logger.info(f"Loaded {MODEL_NAME} v{_model_version} ({MODEL_STAGE})")

@app.on_event("startup")
def startup_event():
    load_model()

@app.post("/predict", response_model=PredictResponse)
def predict(request: PredictRequest):
    if _model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    try:
        df = pd.DataFrame(request.records)
        preds = _model.predict(df).tolist()
        probs = None
        if hasattr(_model, "predict_proba"):
            probs = _model.predict_proba(df)[:, 1].tolist()
        return PredictResponse(
            predictions=preds,
            probabilities=probs,
            model_version=str(_model_version),
            model_name=MODEL_NAME,
        )
    except Exception as e:
        logger.error(f"Prediction error: {e}")
        raise HTTPException(status_code=422, detail=str(e))

@app.post("/reload")
def reload_model():
    """Hot-reload the model from the registry (zero-downtime update)."""
    load_model()
    return {"status": "reloaded", "version": _model_version}

@app.get("/health")
def health():
    return {"status": "ok", "model_version": _model_version}
```

---

## Option 3 — Batch Inference Pipeline

```python
import mlflow
import pandas as pd
from pathlib import Path
import logging

logger = logging.getLogger(__name__)

def run_batch_inference(
    input_path: str,                    # CSV / Parquet
    output_path: str,
    model_name: str = "fraud-classifier",
    stage: str = "Production",
    chunk_size: int = 10_000,
) -> dict:
    model = mlflow.sklearn.load_model(f"models:/{model_name}/{stage}")
    logger.info(f"Loaded {model_name}/{stage}")

    # Get model version for lineage
    client = mlflow.MlflowClient()
    version = client.get_latest_versions(model_name, stages=[stage])[0].version

    chunks_processed = 0
    rows_processed = 0
    results = []

    for chunk in pd.read_csv(input_path, chunksize=chunk_size):
        preds = model.predict(chunk)
        probs = model.predict_proba(chunk)[:, 1] if hasattr(model, "predict_proba") else None
        chunk["prediction"] = preds
        if probs is not None:
            chunk["probability"] = probs
        chunk["model_name"] = model_name
        chunk["model_version"] = version
        results.append(chunk)
        chunks_processed += 1
        rows_processed += len(chunk)

    output = pd.concat(results, ignore_index=True)
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    output.to_parquet(output_path, index=False)
    logger.info(f"Wrote {rows_processed:,} predictions → {output_path}")
    return {"rows": rows_processed, "model_version": version}
```

---

## Input Validation with Model Signature

```python
from mlflow.models import validate_serving_input

# Validate input matches model signature before serving
model_uri = f"models:/fraud-classifier/Production"
sample_input = pd.DataFrame([{"feature_1": 1.2, "feature_2": 0.5}])

try:
    validate_serving_input(model_uri, sample_input)
    print("Input validation passed")
except Exception as e:
    print(f"Input validation failed: {e}")
```

---

## Output Checklist

```
□ Model loaded from registry by stage ("Production"), not by run ID
□ Model version captured and included in response/output for lineage
□ Input validated against model signature before inference
□ Health check endpoint available
□ Hot-reload endpoint available (no restart needed after Registry update)
□ Batch output includes model_name and model_version columns
□ Error handling returns 422 (unprocessable) not 500 for bad inputs
```
