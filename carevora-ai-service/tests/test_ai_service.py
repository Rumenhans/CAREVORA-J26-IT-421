import unittest
import io
import os
import sys
import numpy as np
from PIL import Image
from fastapi.testclient import TestClient

# Ensure service directory is on path
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
if parent_dir not in sys.path:
    sys.path.insert(0, parent_dir)

from main import app
from vision_analyzer import analyze_facial_affect, get_trained_model
from audio_analyzer import analyze_vocal_affect
from ralpa_engine import RALPAEngine

class TestAiMicroservice(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.client = TestClient(app)

    def create_synthetic_image(self, color=(200, 200, 200), size=(64, 64)):
        img = Image.new("RGB", size, color=color)
        buf = io.BytesIO()
        img.save(buf, format="JPEG")
        return buf.getvalue()

    def test_01_root_endpoint(self):
        resp = self.client.get("/")
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertEqual(data["status"], "online")
        self.assertIn("facial", data["models"])
        self.assertIn("vocal", data["models"])
        self.assertIn("trajectory", data["models"])

    def test_02_facial_emotion_model_inference(self):
        model = get_trained_model()
        self.assertIsNotNone(model)

        img_bytes = self.create_synthetic_image()
        res = analyze_facial_affect(image_bytes=img_bytes)

        self.assertIn("dominant_emotion", res)
        self.assertIn("confidence", res)
        self.assertIn("emotion_breakdown_percent", res)
        self.assertIsInstance(res["confidence"], float)
        self.assertTrue(0.0 <= res["confidence"] <= 1.0)
        self.assertEqual(len(res["emotion_breakdown_percent"]), 7)

    def test_03_facial_emotion_photo_endpoint(self):
        img_bytes = self.create_synthetic_image()
        resp = self.client.post(
            "/api/ml/analyze-photo",
            files={"file": ("test_face.jpg", img_bytes, "image/jpeg")}
        )
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertTrue(data["success"])
        self.assertIn("analysis", data)
        self.assertIn("dominant_emotion", data["analysis"])

    def test_04_vocal_acoustic_feature_extraction(self):
        samples = (np.sin(2 * np.pi * 440 * np.linspace(0, 0.5, 8000)) * 60).astype(np.int8).tobytes()
        res = analyze_vocal_affect(audio_bytes=samples)

        self.assertEqual(res["modality"], "Vocal Acoustic Analysis")
        self.assertIn("Rule-Based", res["method"])
        self.assertEqual(res["data_source"], "Acoustic Feature Extraction from Recorded Audio")
        self.assertIn("metrics", res)
        self.assertIn("pitch_modulation", res["metrics"])
        self.assertIn("cadence_stability", res["metrics"])
        self.assertIn("clinical_disclaimer", res)
        self.assertIn("diagnostic", res["clinical_disclaimer"])

    def test_05_vocal_audio_endpoint(self):
        samples = (np.sin(2 * np.pi * 440 * np.linspace(0, 0.5, 8000)) * 50).astype(np.int8).tobytes()
        resp = self.client.post(
            "/api/ml/analyze-audio",
            files={"file": ("test_voice.raw", samples, "application/octet-stream")}
        )
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertTrue(data["success"])
        self.assertEqual(data["analysis"]["modality"], "Vocal Acoustic Analysis")

    def test_06_ralpa_insufficient_history_prevents_misleading_forecast(self):
        engine = RALPAEngine()
        current_scores = {'questionnaire': 75.0, 'facial': 80.0, 'vocal': 60.0, 'social': 80.0}

        # 0 sessions
        res_zero = engine.predict_progression(resident_id=9004, current_scores=current_scores, history_scores=None)
        self.assertTrue(res_zero["is_insufficient_history"])
        self.assertIsNone(res_zero["forecast_14_days"])
        self.assertEqual(res_zero["trajectory"], "BASELINE_ESTABLISHING")

        # 1 session
        res_one = engine.predict_progression(resident_id=9004, current_scores=current_scores, history_scores=[50.0])
        self.assertTrue(res_one["is_insufficient_history"])
        self.assertIsNone(res_one["forecast_14_days"])
        self.assertIn("Insufficient longitudinal history", res_one["message"])

    def test_07_ralpa_longitudinal_14_day_forecast_and_drift(self):
        engine = RALPAEngine()
        current_scores = {'questionnaire': 45.0, 'facial': 40.0, 'vocal': 45.0, 'social': 50.0}
        history_scores = [54.0, 58.0, 64.0, 72.0]

        res = engine.predict_progression(resident_id=9001, current_scores=current_scores, history_scores=history_scores)
        self.assertFalse(res["is_insufficient_history"])
        self.assertIsNotNone(res["forecast_14_days"])
        self.assertEqual(len(res["forecast_14_days"]), 14)
        self.assertGreater(res["baseline_score"], 0)
        self.assertIn("longitudinal_slope", res)
        self.assertIn("contributing_factors", res)
        self.assertGreaterEqual(len(res["recommendations"]), 1)

    def test_08_ralpa_predict_endpoint_api(self):
        req_body = {
            "resident_id": 9001,
            "questionnaire_score": 60.0,
            "history_scores": [50.0, 55.0, 60.0]
        }
        resp = self.client.post("/api/ml/predict-ralpa", json=req_body)
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertTrue(data["success"])
        self.assertIn("forecast_14_days", data["data"])
        self.assertEqual(len(data["data"]["forecast_14_days"]), 14)

if __name__ == "__main__":
    unittest.main()
