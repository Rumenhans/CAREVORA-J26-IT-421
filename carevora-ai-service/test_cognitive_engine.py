"""
Unit and Integration Tests for Cognitive Wellness Component & ACRF Scoring.
Tests formula accuracy, boundaries, invalid input rejections, and FastAPI endpoint behavior.
"""

import math
import unittest
from fastapi.testclient import TestClient

from cognitive_engine import (
    CognitiveEngine,
    CognitiveValidationError,
    ACRF_BASE_WEIGHTS,
    REQUIRED_CATEGORIES,
)
import main


class TestCognitiveEngineUnit(unittest.TestCase):
    """Unit tests for the standalone CognitiveEngine logic."""

    def setUp(self):
        self.engine = CognitiveEngine()

    def test_weights_sum_to_one(self):
        """Verify that fixed ACRF weights sum exactly to 1.00."""
        total_weight = sum(ACRF_BASE_WEIGHTS.values())
        self.assertAlmostEqual(total_weight, 1.00, places=5)
        self.assertEqual(ACRF_BASE_WEIGHTS["memory"], 0.25)
        self.assertEqual(ACRF_BASE_WEIGHTS["attention"], 0.20)
        self.assertEqual(ACRF_BASE_WEIGHTS["orientation"], 0.20)
        self.assertEqual(ACRF_BASE_WEIGHTS["recall"], 0.20)
        self.assertEqual(ACRF_BASE_WEIGHTS["reasoning"], 0.15)

    def test_acrf_formula_calculation(self):
        """
        Verify known score calculation:
        Memory: 80 * 0.25 = 20.0
        Attention: 85 * 0.20 = 17.0
        Orientation: 90 * 0.20 = 18.0
        Recall: 75 * 0.20 = 15.0
        Reasoning: 80 * 0.15 = 12.0
        Expected Total = 20.0 + 17.0 + 18.0 + 15.0 + 12.0 = 82.0
        """
        raw_scores = {
            "memory": 80.0,
            "attention": 85.0,
            "orientation": 90.0,
            "recall": 75.0,
            "reasoning": 80.0,
        }
        res = self.engine.evaluate(raw_scores, resident_id=9001)

        self.assertEqual(res["resident_id"], 9001)
        acrf = res["acrf_assessment"]
        self.assertEqual(acrf["acrf_score"], 82.0)
        self.assertAlmostEqual(acrf["raw_weighted_score"], 82.0, places=4)

        contributions = {c["category"]: c["contribution"] for c in acrf["category_contributions"]}
        self.assertAlmostEqual(contributions["memory"], 20.0)
        self.assertAlmostEqual(contributions["attention"], 17.0)
        self.assertAlmostEqual(contributions["orientation"], 18.0)
        self.assertAlmostEqual(contributions["recall"], 15.0)
        self.assertAlmostEqual(contributions["reasoning"], 12.0)

        # Sum of contributions must equal total score
        self.assertAlmostEqual(sum(contributions.values()), 82.0, places=4)

    def test_boundary_values_all_zero(self):
        """All minimum boundary scores (0.0) must yield ACRF score = 0.0."""
        scores = {cat: 0.0 for cat in REQUIRED_CATEGORIES}
        res = self.engine.evaluate(scores)
        self.assertEqual(res["acrf_assessment"]["acrf_score"], 0.0)

    def test_boundary_values_all_hundred(self):
        """All maximum boundary scores (100.0) must yield ACRF score = 100.0."""
        scores = {cat: 100.0 for cat in REQUIRED_CATEGORIES}
        res = self.engine.evaluate(scores)
        self.assertEqual(res["acrf_assessment"]["acrf_score"], 100.0)

    def test_boundary_values_mixed(self):
        """Mixed boundaries: only Memory is 100, others 0 -> ACRF should be 25.0."""
        scores = {
            "memory": 100.0,
            "attention": 0.0,
            "orientation": 0.0,
            "recall": 0.0,
            "reasoning": 0.0,
        }
        res = self.engine.evaluate(scores)
        self.assertEqual(res["acrf_assessment"]["acrf_score"], 25.0)

    def test_invalid_negative_score(self):
        """Reject negative score (< 0.0)."""
        scores = {
            "memory": -1.0,
            "attention": 80.0,
            "orientation": 80.0,
            "recall": 80.0,
            "reasoning": 80.0,
        }
        with self.assertRaises(CognitiveValidationError):
            self.engine.evaluate(scores)

    def test_invalid_above_hundred_score(self):
        """Reject score exceeding maximum (> 100.0)."""
        scores = {
            "memory": 100.1,
            "attention": 80.0,
            "orientation": 80.0,
            "recall": 80.0,
            "reasoning": 80.0,
        }
        with self.assertRaises(CognitiveValidationError):
            self.engine.evaluate(scores)

    def test_invalid_nan_score(self):
        """Reject NaN (Not a Number) values."""
        scores = {
            "memory": float("nan"),
            "attention": 80.0,
            "orientation": 80.0,
            "recall": 80.0,
            "reasoning": 80.0,
        }
        with self.assertRaises(CognitiveValidationError):
            self.engine.evaluate(scores)

    def test_invalid_inf_score(self):
        """Reject infinite values."""
        scores = {
            "memory": float("inf"),
            "attention": 80.0,
            "orientation": 80.0,
            "recall": 80.0,
            "reasoning": 80.0,
        }
        with self.assertRaises(CognitiveValidationError):
            self.engine.evaluate(scores)

    def test_invalid_boolean_score(self):
        """Reject boolean values (do not cast True -> 1.0)."""
        scores = {
            "memory": True,
            "attention": 80.0,
            "orientation": 80.0,
            "recall": 80.0,
            "reasoning": 80.0,
        }
        with self.assertRaises(CognitiveValidationError):
            self.engine.evaluate(scores)

    def test_invalid_string_score(self):
        """Reject unparseable string values."""
        scores = {
            "memory": "eighty",
            "attention": 80.0,
            "orientation": 80.0,
            "recall": 80.0,
            "reasoning": 80.0,
        }
        with self.assertRaises(CognitiveValidationError):
            self.engine.evaluate(scores)

    def test_invalid_missing_category(self):
        """Reject missing required categories (e.g., missing reasoning)."""
        scores = {
            "memory": 80.0,
            "attention": 80.0,
            "orientation": 80.0,
            "recall": 80.0,
            # 'reasoning' intentionally omitted
        }
        with self.assertRaises(CognitiveValidationError):
            self.engine.evaluate(scores)

    def test_ml_model_status_unavailable(self):
        """Verify the Random Forest model is declared as unavailable and no predictions are fabricated."""
        scores = {cat: 80.0 for cat in REQUIRED_CATEGORIES}
        res = self.engine.evaluate(scores)
        ml = res["ml_model_evaluation"]
        self.assertFalse(ml["available"])
        self.assertIsNone(ml["prediction"])
        self.assertIsNone(ml["probabilities"])
        self.assertEqual(ml["model_type"], "RandomForestClassifier")
        self.assertIn("unavailable", ml["status_message"].lower())


class TestCognitiveEndpointIntegration(unittest.TestCase):
    """Integration tests for FastAPI endpoints using TestClient."""

    def setUp(self):
        self.client = TestClient(main.app)

    def test_get_root_online_and_includes_cognitive(self):
        """Verify GET / health check endpoint reports online and includes cognitive engine."""
        resp = self.client.get("/")
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertEqual(data["status"], "online")
        self.assertIn("cognitive", data["models"])

    def test_predict_cognitive_nested_scores(self):
        """Test POST /api/ml/predict-cognitive with standard nested 'scores' payload."""
        payload = {
            "resident_id": 9001,
            "scores": {
                "memory": 80.0,
                "attention": 85.0,
                "orientation": 90.0,
                "recall": 75.0,
                "reasoning": 80.0,
            }
        }
        resp = self.client.post("/api/ml/predict-cognitive", json=payload)
        self.assertEqual(resp.status_code, 200)
        body = resp.json()

        self.assertTrue(body["success"])
        data = body["data"]
        self.assertEqual(data["resident_id"], 9001)

        acrf = data["acrf_assessment"]
        self.assertEqual(acrf["acrf_score"], 82.0)
        self.assertEqual(len(acrf["category_contributions"]), 5)
        self.assertEqual(acrf["weights_applied"]["memory"], 0.25)
        self.assertEqual(acrf["weights_applied"]["reasoning"], 0.15)

        ml = data["ml_model_evaluation"]
        self.assertFalse(ml["available"])
        self.assertIsNone(ml["prediction"])

    def test_predict_cognitive_flat_scores(self):
        """Test POST /api/ml/predict-cognitive with flat payload fields."""
        payload = {
            "resident_id": 42,
            "memory": 100.0,
            "attention": 100.0,
            "orientation": 100.0,
            "recall": 100.0,
            "reasoning": 100.0,
        }
        resp = self.client.post("/api/ml/predict-cognitive", json=payload)
        self.assertEqual(resp.status_code, 200)
        body = resp.json()
        self.assertEqual(body["data"]["acrf_assessment"]["acrf_score"], 100.0)

    def test_predict_cognitive_rejects_out_of_bounds(self):
        """Test POST /api/ml/predict-cognitive rejects values > 100 with HTTP 422."""
        payload = {
            "scores": {
                "memory": 105.0,
                "attention": 80.0,
                "orientation": 80.0,
                "recall": 80.0,
                "reasoning": 80.0,
            }
        }
        resp = self.client.post("/api/ml/predict-cognitive", json=payload)
        self.assertEqual(resp.status_code, 422)

    def test_predict_cognitive_rejects_missing_field(self):
        """Test POST /api/ml/predict-cognitive rejects payload missing a category."""
        payload = {
            "scores": {
                "memory": 80.0,
                "attention": 80.0,
                "orientation": 80.0,
                "recall": 80.0,
                # 'reasoning' missing
            }
        }
        resp = self.client.post("/api/ml/predict-cognitive", json=payload)
        self.assertEqual(resp.status_code, 422)

    def test_predict_cognitive_rejects_nan_and_inf(self):
        """Test POST /api/ml/predict-cognitive rejects NaN and Inf values."""
        # NaN in JSON cannot be serialized as standard float, but string 'NaN' will be rejected by Pydantic
        payload = {
            "scores": {
                "memory": "NaN",
                "attention": 80.0,
                "orientation": 80.0,
                "recall": 80.0,
                "reasoning": 80.0,
            }
        }
        resp = self.client.post("/api/ml/predict-cognitive", json=payload)
        self.assertEqual(resp.status_code, 422)

    def test_existing_ralpa_endpoint_unbroken(self):
        """Verify that existing RALPA progression endpoint continues to function without regression."""
        payload = {
            "resident_id": 9001,
            "questionnaire_score": 85.0,
            "social_score": 80.0,
        }
        resp = self.client.post("/api/ml/predict-ralpa", json=payload)
        self.assertEqual(resp.status_code, 200)
        body = resp.json()
        self.assertTrue(body["success"])
        self.assertIn("forecast_7_days", body["data"])

    def test_artifact_loaded_and_verified(self):
        """Verify that the joblib artifact loaded successfully and matches expected Colab parameters."""
        engine = CognitiveEngine()
        self.assertTrue(engine.model_loaded, f"Model failed to load: {engine.load_error}")
        self.assertIsNotNone(engine.model_pipeline)
        self.assertIsNotNone(engine.acrf_transformer)
        self.assertEqual(len(engine.expected_features), 31)
        self.assertEqual(engine.labels, ["Low", "Moderate", "High"])
        self.assertEqual(engine.alert_threshold, 0.48)
        self.assertEqual(engine.model_name, "Random Forest")
        self.assertEqual(engine.feature_set, "B: raw + ACRF")

        # Verify pipeline steps
        steps = list(engine.model_pipeline.named_steps.keys())
        self.assertEqual(steps, ["imp", "sc", "model"])

    def test_ml_prediction_with_valid_complete_features(self):
        """Test model evaluation when all 31 features are legitimately provided."""
        engine = CognitiveEngine()
        raw_scores = {"memory": 82.0, "attention": 85.0, "orientation": 90.0, "recall": 78.0, "reasoning": 80.0}
        accuracies = {"memory": 0.82, "attention": 0.85, "orientation": 0.90, "recall": 0.78, "reasoning": 0.80}
        r_times = {"memory": 2.4, "attention": 2.2, "orientation": 1.9, "recall": 2.5, "reasoning": 2.3}

        res = engine.evaluate(
            raw_scores=raw_scores,
            resident_id=101,
            age=76.0,
            education_years=12.0,
            accuracies=accuracies,
            response_times=r_times,
            assessment_number=1,
        )

        ml = res["ml_model_evaluation"]
        self.assertTrue(ml["available"])
        self.assertIn(ml["prediction"], ["Low", "Moderate", "High"])
        self.assertIsInstance(ml["probabilities"], dict)
        self.assertIn("Low", ml["probabilities"])
        self.assertIn("Moderate", ml["probabilities"])
        self.assertIn("High", ml["probabilities"])
        prob_sum = sum(ml["probabilities"].values())
        self.assertAlmostEqual(prob_sum, 1.0, places=2)
        self.assertEqual(ml["alert_threshold"], 0.48)
        self.assertIsInstance(ml["alert_triggered"], bool)
        self.assertEqual(ml["feature_set"], "B: raw + ACRF")
        self.assertIn("synthetic data", ml["disclaimer"].lower())

    def test_ml_prediction_high_risk_triggered(self):
        """Test model identifies high-risk profile with low scores and elevated response times."""
        engine = CognitiveEngine()
        raw_scores = {"memory": 25.0, "attention": 30.0, "orientation": 35.0, "recall": 20.0, "reasoning": 25.0}
        accuracies = {"memory": 0.25, "attention": 0.30, "orientation": 0.35, "recall": 0.20, "reasoning": 0.25}
        r_times = {"memory": 5.8, "attention": 5.2, "orientation": 4.5, "recall": 5.9, "reasoning": 5.4}

        res = engine.evaluate(
            raw_scores=raw_scores,
            resident_id=102,
            age=85.0,
            education_years=6.0,
            accuracies=accuracies,
            response_times=r_times,
            assessment_number=1,
        )

        ml = res["ml_model_evaluation"]
        self.assertTrue(ml["available"])
        self.assertEqual(ml["prediction"], "High")
        self.assertTrue(ml["alert_triggered"])
        self.assertGreaterEqual(ml["probabilities"]["High"], 0.48)

    def test_ml_prediction_with_longitudinal_history(self):
        """Test model evaluation incorporating temporal assessment history via ACRF transformer."""
        engine = CognitiveEngine()
        history = [
            {
                "assessment_number": 1,
                "resident_id": 103,
                "memory_score": 85.0,
                "attention_score": 85.0,
                "orientation_score": 90.0,
                "recall_score": 80.0,
                "reasoning_score": 80.0,
                "memory_response_time": 2.3,
                "attention_response_time": 2.2,
                "orientation_response_time": 2.0,
                "recall_response_time": 2.4,
                "reasoning_response_time": 2.3,
            }
        ]
        raw_scores = {"memory": 60.0, "attention": 65.0, "orientation": 70.0, "recall": 55.0, "reasoning": 60.0}
        accuracies = {"memory": 0.60, "attention": 0.65, "orientation": 0.70, "recall": 0.55, "reasoning": 0.60}
        r_times = {"memory": 3.6, "attention": 3.4, "orientation": 3.0, "recall": 3.8, "reasoning": 3.5}

        res = engine.evaluate(
            raw_scores=raw_scores,
            resident_id=103,
            age=80.0,
            education_years=10.0,
            accuracies=accuracies,
            response_times=r_times,
            assessment_number=2,
            history=history,
        )

        ml = res["ml_model_evaluation"]
        self.assertTrue(ml["available"])
        self.assertIsNotNone(ml["prediction"])

    def test_ml_prediction_declined_missing_age(self):
        """Verify model declines inference when demographic age is missing."""
        engine = CognitiveEngine()
        raw_scores = {"memory": 80.0, "attention": 80.0, "orientation": 80.0, "recall": 80.0, "reasoning": 80.0}
        accuracies = {"memory": 0.8, "attention": 0.8, "orientation": 0.8, "recall": 0.8, "reasoning": 0.8}
        r_times = {"memory": 2.5, "attention": 2.5, "orientation": 2.5, "recall": 2.5, "reasoning": 2.5}

        res = engine.evaluate(
            raw_scores=raw_scores,
            age=None,  # missing age
            education_years=12.0,
            accuracies=accuracies,
            response_times=r_times,
        )
        ml = res["ml_model_evaluation"]
        self.assertFalse(ml["available"])
        self.assertIn("age", ml["missing_features"])
        self.assertIsNone(ml["prediction"])

    def test_ml_prediction_declined_missing_education(self):
        """Verify model declines inference when education_years is missing."""
        engine = CognitiveEngine()
        raw_scores = {"memory": 80.0, "attention": 80.0, "orientation": 80.0, "recall": 80.0, "reasoning": 80.0}
        accuracies = {"memory": 0.8, "attention": 0.8, "orientation": 0.8, "recall": 0.8, "reasoning": 0.8}
        r_times = {"memory": 2.5, "attention": 2.5, "orientation": 2.5, "recall": 2.5, "reasoning": 2.5}

        res = engine.evaluate(
            raw_scores=raw_scores,
            age=75.0,
            education_years=None,  # missing education
            accuracies=accuracies,
            response_times=r_times,
        )
        ml = res["ml_model_evaluation"]
        self.assertFalse(ml["available"])
        self.assertIn("education_years", ml["missing_features"])

    def test_ml_prediction_declined_missing_accuracies(self):
        """Verify model declines inference when accuracies are missing or incomplete."""
        engine = CognitiveEngine()
        raw_scores = {"memory": 80.0, "attention": 80.0, "orientation": 80.0, "recall": 80.0, "reasoning": 80.0}
        r_times = {"memory": 2.5, "attention": 2.5, "orientation": 2.5, "recall": 2.5, "reasoning": 2.5}

        res = engine.evaluate(
            raw_scores=raw_scores,
            age=75.0,
            education_years=12.0,
            accuracies={"memory": 0.8},  # 4 domains missing
            response_times=r_times,
        )
        ml = res["ml_model_evaluation"]
        self.assertFalse(ml["available"])
        self.assertIn("attention_accuracy", ml["missing_features"])

    def test_ml_prediction_declined_missing_response_times(self):
        """Verify model declines inference when response times are missing."""
        engine = CognitiveEngine()
        raw_scores = {"memory": 80.0, "attention": 80.0, "orientation": 80.0, "recall": 80.0, "reasoning": 80.0}
        accuracies = {"memory": 0.8, "attention": 0.8, "orientation": 0.8, "recall": 0.8, "reasoning": 0.8}

        res = engine.evaluate(
            raw_scores=raw_scores,
            age=75.0,
            education_years=12.0,
            accuracies=accuracies,
            response_times=None,  # missing response times
        )
        ml = res["ml_model_evaluation"]
        self.assertFalse(ml["available"])
        self.assertIn("memory_response_time", ml["missing_features"])

    def test_predict_cognitive_endpoint_complete_ml_features(self):
        """Test POST /api/ml/predict-cognitive with complete ML features producing model prediction."""
        payload = {
            "resident_id": 9002,
            "scores": {
                "memory": 85.0,
                "attention": 85.0,
                "orientation": 90.0,
                "recall": 80.0,
                "reasoning": 80.0,
            },
            "age": 78.0,
            "education_years": 14.0,
            "accuracies": {
                "memory": 0.85,
                "attention": 0.85,
                "orientation": 0.90,
                "recall": 0.80,
                "reasoning": 0.80,
            },
            "response_times": {
                "memory": 2.3,
                "attention": 2.1,
                "orientation": 1.8,
                "recall": 2.4,
                "reasoning": 2.2,
            },
            "assessment_number": 1,
        }
        resp = self.client.post("/api/ml/predict-cognitive", json=payload)
        self.assertEqual(resp.status_code, 200)
        body = resp.json()
        self.assertTrue(body["success"])
        ml = body["data"]["ml_model_evaluation"]
        self.assertTrue(ml["available"])
        self.assertIn(ml["prediction"], ["Low", "Moderate", "High"])
        self.assertIsNotNone(ml["probabilities"])
        self.assertEqual(ml["alert_threshold"], 0.48)

    def test_predict_cognitive_endpoint_backward_compatible_no_ml_features(self):
        """Test POST /api/ml/predict-cognitive with standard baseline scores remains fully functional."""
        payload = {
            "resident_id": 9003,
            "scores": {
                "memory": 80.0,
                "attention": 80.0,
                "orientation": 80.0,
                "recall": 80.0,
                "reasoning": 80.0,
            }
        }
        resp = self.client.post("/api/ml/predict-cognitive", json=payload)
        self.assertEqual(resp.status_code, 200)
        body = resp.json()
        self.assertTrue(body["success"])
        data = body["data"]
        self.assertEqual(data["acrf_assessment"]["acrf_score"], 80.0)
        ml = data["ml_model_evaluation"]
        self.assertFalse(ml["available"])
        self.assertIsNone(ml["prediction"])


if __name__ == "__main__":
    unittest.main()
