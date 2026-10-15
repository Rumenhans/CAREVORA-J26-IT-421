# Emotional wellness risk models (Colab-trained)

| File | Task | Output |
|---|---|---|
| `carevora_high_risk_model.joblib` | `high_risk_label` (binary) | dict: `models` (4: 2xLightGBM, LogReg pipeline, HistGB), `features` (149), `threshold` (0.31) -> average `predict_proba(...)[:,1]` of the 4 models, high risk if >= threshold |
| `carevora_trajectory_model.joblib` | `trajectory_label` (3 classes) | dict: `models` (3: 2xLightGBM, LogReg pipeline), `features` (149), `classes` -> average `predict_proba`, argmax -> class |

- Trained with scikit-learn **1.6.1** (matches `requirements.txt`) + `lightgbm`. Add `lightgbm` to requirements if these are loaded by the service.
- Inputs are the 149 columns in `features`: the base visit features plus per-resident past-visit features
  (lag1/lag2, expanding mean/std, rolling-3, vs-history, delta1) and 4 composites. A resident's visit history is required.
- Trained on the **synthetic v2** dataset (`carevora_synthetic_dataset_v2`, NOISE=1.0, LABEL_FLIP=2%).
  Reported accuracy (~95% / ~98.6%) reflects the simulator's low noise, not real-world performance.
