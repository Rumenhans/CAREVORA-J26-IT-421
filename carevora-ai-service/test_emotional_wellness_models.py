"""
Unit and Integration Tests for Emotional Wellness Component & Colab Models Integration.
Verifies:
1. Loading of Colab-trained models (carevora_high_risk_model, carevora_trajectory_model).
2. 149-feature schema alignment and historical feature transformations.
3. Insufficient history guard (0 and 1 session handling).
4. Longitudinal trajectory prediction (improving, stable, deteriorating).
5. Chronological history ordering, baseline deviation, and slope regression.
6. Robustness against missing, None, and out-of-range inputs.
7. FastAPI endpoint POST /api/ml/predict-ralpa response structure and backward compatibility.
"""

import math
import unittest
import numpy as np
import pandas as pd
from fastapi.testclient import TestClient

from ralpa_engine import RALPAEngine, CORE_BASE_FEATURES, BASE_FEATURES_ORDER
import main


class TestEmotionalWellnessModels(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.client = TestClient(main.app)
        cls.engine = RALPAEngine()

    def test_01_models_loaded_successfully(self):
        """Verify both Colab joblib models loaded without errors."""
        self.assertTrue(
            self.engine.models_loaded,
            f"Colab models failed to load: {self.engine.load_error}"
        )
        self.assertIsNotNone(self.engine.high_risk_artifact)
        self.assertIsNotNone(self.engine.trajectory_artifact)

    def test_02_model_schemas_and_hyperparameters(self):
        """Verify model ensemble counts, thresholds, and classes."""
        self.assertEqual(len(self.engine.expected_features), 149)
        self.assertAlmostEqual(self.engine.high_risk_threshold, 0.31, places=2)
        self.assertEqual(sorted(self.engine.trajectory_classes), ["deteriorating", "improving", "stable"])

        # High-risk ensemble: 4 models
        h_models = self.engine.high_risk_artifact["models"]
        self.assertEqual(len(h_models), 4)
        self.assertIn("lgb", h_models)
        self.assertIn("lgb2", h_models)
        self.assertIn("lr", h_models)
        self.assertIn("hgb", h_models)

        # Trajectory ensemble: 3 models
        t_models = self.engine.trajectory_artifact["models"]
        self.assertEqual(len(t_models), 3)

    def test_03_149_feature_vector_generation(self):
        """Verify that the 149-feature vector matches expected order and has no NaNs."""
        current_scores = {
            "questionnaire": 85.0,
            "facial": 80.0,
            "vocal": 75.0,
            "social": 70.0
        }
        history = [70.0, 75.0, 80.0]
        feat_df = self.engine._build_feature_row(current_scores, history)

        self.assertEqual(feat_df.shape, (1, 149))
        self.assertEqual(list(feat_df.columns), self.engine.expected_features)
        self.assertFalse(feat_df.isna().any().any(), "Feature vector contains unexpected NaNs")

        # Verify composite features
        self.assertIn("neg_affect", feat_df.columns)
        self.assertIn("social_deficit", feat_df.columns)
        self.assertIn("wellness_gap", feat_df.columns)
        self.assertIn("contact_total", feat_df.columns)

    def test_04_insufficient_history_zero_sessions(self):
        """Zero historical sessions must trigger BASELINE_ESTABLISHING and suppress forecasts."""
        res = self.engine.predict_progression(
            resident_id=101,
            current_scores={"questionnaire": 85.0, "facial": 80.0, "vocal": 80.0, "social": 80.0},
            history_scores=[]
        )
        self.assertTrue(res["is_insufficient_history"])
        self.assertEqual(res["trajectory"], "BASELINE_ESTABLISHING")
        self.assertIsNone(res["forecast_14_days"])
        self.assertIsNone(res["forecast_7_days"])
        self.assertEqual(res["baseline_deviation"], 0.0)

    def test_05_insufficient_history_one_session(self):
        """Single historical session must also trigger BASELINE_ESTABLISHING."""
        res = self.engine.predict_progression(
            resident_id=102,
            current_scores={"questionnaire": 85.0, "facial": 80.0, "vocal": 80.0, "social": 80.0},
            history_scores=[82.0]
        )
        self.assertTrue(res["is_insufficient_history"])
        self.assertEqual(res["trajectory"], "BASELINE_ESTABLISHING")
        self.assertIsNone(res["forecast_14_days"])
        self.assertIsNone(res["forecast_7_days"])

    def test_06_stable_trajectory_two_sessions(self):
        """Two identical sessions must yield STABLE trajectory and continuous projections."""
        res = self.engine.predict_progression(
            resident_id=103,
            current_scores={"questionnaire": 80.0, "facial": 80.0, "vocal": 80.0, "social": 80.0},
            history_scores=[80.0, 80.0]
        )
        self.assertFalse(res["is_insufficient_history"])
        self.assertEqual(res["trajectory"], "STABLE")
        self.assertAlmostEqual(res["baseline_deviation"], 0.0, places=1)
        self.assertIsNotNone(res["forecast_14_days"])
        self.assertEqual(len(res["forecast_14_days"]), 14)
        self.assertEqual(len(res["forecast_7_days"]), 7)

    def test_07_improving_trajectory(self):
        """Consistently improving wellness history must result in IMPROVING trajectory."""
        res = self.engine.predict_progression(
            resident_id=104,
            current_scores={"questionnaire": 90.0, "facial": 88.0, "vocal": 85.0, "social": 85.0},
            history_scores=[50.0, 60.0, 70.0, 80.0]
        )
        self.assertFalse(res["is_insufficient_history"])
        self.assertEqual(res["trajectory"], "IMPROVING")
        self.assertLess(res["baseline_deviation"], 0.0)
        self.assertEqual(res["risk_level"], "LOW")

    def test_08_deteriorating_trajectory_and_high_risk_alert(self):
        """Marked decline in scores must result in DETERIORATING trajectory and HIGH risk."""
        res = self.engine.predict_progression(
            resident_id=105,
            current_scores={"questionnaire": 35.0, "facial": 40.0, "vocal": 45.0, "social": 30.0},
            history_scores=[85.0, 75.0, 65.0, 50.0]
        )
        self.assertFalse(res["is_insufficient_history"])
        self.assertEqual(res["trajectory"], "DETERIORATING")
        self.assertGreater(res["baseline_deviation"], 0.0)
        self.assertEqual(res["risk_level"], "HIGH")

        # Verify ML model evaluation object is present
        ml_eval = res["ml_models_evaluation"]
        self.assertTrue(ml_eval["models_loaded"])
        self.assertIsNotNone(ml_eval["high_risk_model"])
        self.assertIsNotNone(ml_eval["trajectory_model"])

    def test_09_input_sanitization_and_clamping(self):
        """Out-of-range and invalid non-numeric inputs must be clamped and sanitized safely."""
        res = self.engine.predict_progression(
            resident_id=106,
            current_scores={"questionnaire": -50.0, "facial": 250.0, "vocal": None, "social": "invalid"},
            history_scores=[-100.0, 150.0, "bad", None, 75.0]
        )
        self.assertTrue(0.0 <= res["current_wellness_index"] <= 100.0)
        self.assertTrue(0.0 <= res["current_risk_score"] <= 100.0)
        self.assertFalse(math.isnan(res["current_risk_score"]))

    def test_10_fastapi_predict_ralpa_endpoint_integration(self):
        """Test live FastAPI POST /api/ml/predict-ralpa endpoint."""
        payload = {
            "resident_id": 9001,
            "questionnaire_score": 85.0,
            "social_score": 80.0,
            "history_scores": [75.0, 78.0, 80.0],
            "score_domain": "wellness"
        }
        resp = self.client.post("/api/ml/predict-ralpa", json=payload)
        self.assertEqual(resp.status_code, 200)

        body = resp.json()
        self.assertTrue(body["success"])
        data = body["data"]

        # Ensure all required contract fields exist
        self.assertIn("current_wellness_index", data)
        self.assertIn("current_risk_score", data)
        self.assertIn("risk_level", data)
        self.assertIn("trajectory", data)
        self.assertIn("baseline_score", data)
        self.assertIn("baseline_deviation", data)
        self.assertIn("forecast_14_days", data)
        self.assertIn("forecast_7_days", data)
        self.assertIn("contributing_factors", data)
        self.assertIn("recommendations", data)
        self.assertIn("ml_models_evaluation", data)
        self.assertIn("modality_breakdown", data)


if __name__ == "__main__":
    unittest.main()
