import unittest
import numpy as np
import sys
import os

# Add service directory to path
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
if parent_dir not in sys.path:
    sys.path.insert(0, parent_dir)

from ralpa_engine import RALPAEngine

class TestRALPARegression(unittest.TestCase):
    def setUp(self):
        self.engine = RALPAEngine()

    def test_01_insufficient_history_cases(self):
        # Case A: 0 historical sessions
        res_0 = self.engine.predict_progression(
            resident_id=1,
            current_scores={'questionnaire': 85.0, 'facial': 85.0, 'vocal': 80.0, 'social': 80.0},
            history_scores=[]
        )
        self.assertTrue(res_0["is_insufficient_history"])
        self.assertEqual(res_0["trajectory"], "BASELINE_ESTABLISHING")
        self.assertIsNone(res_0["forecast_14_days"])
        self.assertEqual(res_0["current_wellness_index"], 83.0)
        self.assertEqual(res_0["current_risk_score"], 17.0)
        self.assertEqual(res_0["baseline_score"], 17.0)
        self.assertEqual(res_0["baseline_deviation"], 0.0)

        # Case B: 1 historical session
        res_1 = self.engine.predict_progression(
            resident_id=1,
            current_scores={'questionnaire': 85.0, 'facial': 85.0, 'vocal': 80.0, 'social': 80.0},
            history_scores=[80.0]
        )
        self.assertTrue(res_1["is_insufficient_history"])
        self.assertEqual(res_1["trajectory"], "BASELINE_ESTABLISHING")
        self.assertIsNone(res_1["forecast_14_days"])

    def test_02_stable_wellness_scores(self):
        # Constant wellness of 80.0 across history and current observation
        res = self.engine.predict_progression(
            resident_id=2,
            current_scores={'questionnaire': 80.0, 'facial': 80.0, 'vocal': 80.0, 'social': 80.0},
            history_scores=[80.0, 80.0, 80.0]
        )
        self.assertFalse(res["is_insufficient_history"])
        self.assertEqual(res["trajectory"], "STABLE")
        self.assertEqual(res["current_wellness_index"], 80.0)
        self.assertEqual(res["current_risk_score"], 20.0)
        self.assertEqual(res["baseline_score"], 20.0)
        self.assertEqual(res["baseline_deviation"], 0.0)
        self.assertEqual(res["longitudinal_slope"], 0.0)
        self.assertIsNotNone(res["forecast_14_days"])
        self.assertEqual(len(res["forecast_14_days"]), 14)
        self.assertEqual(res["forecast_14_days"], [20.0] * 14)

    def test_03_increasing_wellness_scores(self):
        # Wellness improving: 60 -> 70 -> 80 (history), current = 90
        # Historical risk: 40 -> 30 -> 20, current risk = 10
        res = self.engine.predict_progression(
            resident_id=3,
            current_scores={'questionnaire': 90.0, 'facial': 90.0, 'vocal': 90.0, 'social': 90.0},
            history_scores=[60.0, 70.0, 80.0]
        )
        self.assertFalse(res["is_insufficient_history"])
        self.assertEqual(res["trajectory"], "IMPROVING")
        self.assertEqual(res["current_wellness_index"], 90.0)
        self.assertEqual(res["current_risk_score"], 10.0)
        self.assertEqual(res["baseline_score"], 30.0) # mean of [40, 30, 20]
        self.assertEqual(res["baseline_deviation"], -20.0) # 10 - 30
        self.assertLess(res["longitudinal_slope"], -1.2)
        self.assertEqual(res["longitudinal_slope"], -10.0)
        self.assertEqual(len(res["forecast_14_days"]), 14)
        # All forecast points should be non-increasing and bounded >= 0
        for i in range(len(res["forecast_14_days"]) - 1):
            self.assertGreaterEqual(res["forecast_14_days"][i], res["forecast_14_days"][i+1])
        self.assertGreaterEqual(res["forecast_14_days"][-1], 0.0)

    def test_04_decreasing_wellness_scores(self):
        # Wellness deteriorating: 85 -> 75 -> 65 (history), current = 50
        # Historical risk: 15 -> 25 -> 35, current risk = 50
        res = self.engine.predict_progression(
            resident_id=4,
            current_scores={'questionnaire': 50.0, 'facial': 50.0, 'vocal': 50.0, 'social': 50.0},
            history_scores=[85.0, 75.0, 65.0]
        )
        self.assertFalse(res["is_insufficient_history"])
        self.assertEqual(res["trajectory"], "DETERIORATING")
        self.assertEqual(res["current_wellness_index"], 50.0)
        self.assertEqual(res["current_risk_score"], 50.0)
        self.assertEqual(res["baseline_score"], 25.0) # mean of [15, 25, 35]
        self.assertEqual(res["baseline_deviation"], 25.0) # 50 - 25
        self.assertGreater(res["longitudinal_slope"], 1.2)
        self.assertEqual(res["longitudinal_slope"], 11.5)
        self.assertEqual(len(res["forecast_14_days"]), 14)
        # Forecast points should project increasing risk bounded <= 100
        for i in range(len(res["forecast_14_days"]) - 1):
            self.assertLessEqual(res["forecast_14_days"][i], res["forecast_14_days"][i+1])
        self.assertLessEqual(res["forecast_14_days"][-1], 100.0)

    def test_05_missing_and_out_of_range_clamping(self):
        # Out-of-range negative/large scores and non-numeric inputs
        res = self.engine.predict_progression(
            resident_id=5,
            current_scores={'questionnaire': -50.0, 'facial': None, 'vocal': 180.0, 'social': 'invalid'},
            history_scores=[None, -20.0, 140.0, 'bad_str']
        )
        self.assertFalse(res["is_insufficient_history"])
        # -50 clamped to 0.0; facial None -> 80.0; vocal 180 -> 100.0; social invalid -> 80.0
        # fused = 0*0.4 + 80*0.25 + 80*0.2 + 100*0.15 = 0 + 20 + 16 + 15 = 51.0
        # risk = 100 - 51.0 = 49.0
        self.assertEqual(res["current_wellness_index"], 51.0)
        self.assertEqual(res["current_risk_score"], 49.0)
        # history: -20 clamped to 0 -> risk 100; 140 clamped to 100 -> risk 0. mean risk = 50.0
        self.assertEqual(res["baseline_score"], 50.0)
        self.assertEqual(res["baseline_deviation"], -1.0)
        self.assertEqual(len(res["forecast_14_days"]), 14)
        for pt in res["forecast_14_days"]:
            self.assertTrue(0.0 <= pt <= 100.0)
            self.assertFalse(np.isnan(pt))
            self.assertFalse(np.isinf(pt))

if __name__ == "__main__":
    unittest.main()
