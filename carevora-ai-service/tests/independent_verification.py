import numpy as np
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from ralpa_engine import RALPAEngine

engine = RALPAEngine()

cases = [
    {
        'id': 'case_0_history',
        'desc': 'Zero historical sessions',
        'current': {'questionnaire': 85.0, 'facial': 85.0, 'vocal': 80.0, 'social': 80.0},
        'history': []
    },
    {
        'id': 'case_1_history',
        'desc': 'One historical session',
        'current': {'questionnaire': 85.0, 'facial': 85.0, 'vocal': 80.0, 'social': 80.0},
        'history': [80.0]
    },
    {
        'id': 'case_stable',
        'desc': 'Stable wellness scores',
        'current': {'questionnaire': 80.0, 'facial': 80.0, 'vocal': 80.0, 'social': 80.0},
        'history': [80.0, 80.0, 80.0]
    },
    {
        'id': 'case_increasing',
        'desc': 'Increasing wellness scores (Improving)',
        'current': {'questionnaire': 90.0, 'facial': 90.0, 'vocal': 90.0, 'social': 90.0},
        'history': [60.0, 70.0, 80.0]
    },
    {
        'id': 'case_decreasing',
        'desc': 'Decreasing wellness scores (Deteriorating)',
        'current': {'questionnaire': 50.0, 'facial': 50.0, 'vocal': 50.0, 'social': 50.0},
        'history': [85.0, 75.0, 65.0]
    },
    {
        'id': 'case_out_of_range',
        'desc': 'Missing and out-of-range values',
        'current': {'questionnaire': -50.0, 'facial': None, 'vocal': 180.0, 'social': 'invalid'},
        'history': [None, -20.0, 140.0, 'bad_str']
    }
]

for c in cases:
    print('='*75)
    print(f"CASE: {c['desc']}")
    print('='*75)
    
    # 1. Independent Step-by-Step Mathematical Calculation
    def clean(val, default):
        try:
            f = float(val)
            if np.isnan(f) or np.isinf(f):
                return default
            return float(np.clip(f, 0.0, 100.0))
        except (ValueError, TypeError):
            return default
            
    q = clean(c['current'].get('questionnaire'), 85.0)
    f = clean(c['current'].get('facial'), 85.0)
    v = clean(c['current'].get('vocal'), 80.0)
    s = clean(c['current'].get('social'), 80.0)
    
    manual_fused = round(q*0.40 + s*0.25 + f*0.20 + v*0.15, 4)
    manual_fused_clamped = min(100.0, max(0.0, manual_fused))
    manual_risk = round(100.0 - manual_fused_clamped, 1)
    
    manual_hist_risk = []
    for h in c['history']:
        try:
            val = float(h)
            if not (np.isnan(val) or np.isinf(val)):
                clamped = min(100.0, max(0.0, val))
                manual_hist_risk.append(round(100.0 - clamped, 1))
        except (ValueError, TypeError):
            continue
            
    if len(manual_hist_risk) < 2:
        exp_insufficient = True
        exp_baseline = manual_risk
        exp_dev = 0.0
        exp_slope = None
        exp_traj = 'BASELINE_ESTABLISHING'
        exp_forecast = None
    else:
        exp_insufficient = False
        exp_baseline = round(float(np.mean(manual_hist_risk)), 1)
        exp_dev = round(manual_risk - float(np.mean(manual_hist_risk)), 1)
        extended = manual_hist_risk + [manual_risk]
        time_x = np.arange(len(extended))
        slope, _ = np.polyfit(time_x, extended, 1)
        exp_slope = round(float(slope), 2)
        if slope > 1.2 or exp_dev > 10.0:
            exp_traj = 'DETERIORATING'
        elif slope < -1.2 or exp_dev < -10.0:
            exp_traj = 'IMPROVING'
        else:
            exp_traj = 'STABLE'
        exp_forecast = [round(float(np.clip(manual_risk + (day * slope * 0.4), 0.0, 100.0)), 1) for day in range(1, 15)]

    # 2. Actual RALPA Implementation Execution
    act = engine.predict_progression(resident_id=1, current_scores=c['current'], history_scores=c['history'])
    
    print(f"Manual Fused Wellness: {manual_fused_clamped:.1f} | Actual: {act.get('current_wellness_index')}")
    print(f"Manual Current Risk:   {manual_risk:.1f} | Actual: {act.get('current_risk_score')}")
    print(f"Manual Baseline:       {exp_baseline} | Actual: {act.get('baseline_score')}")
    print(f"Manual Deviation:      {exp_dev} | Actual: {act.get('baseline_deviation')}")
    print(f"Manual Slope:          {exp_slope} | Actual: {act.get('longitudinal_slope')}")
    print(f"Manual Trajectory:     {exp_traj} | Actual: {act.get('trajectory')}")
    print(f"Manual Forecast (4pts):{exp_forecast[:4] if exp_forecast else None} | Actual: {act.get('forecast_14_days')[:4] if act.get('forecast_14_days') else None}")
    
    match = (
        act.get('is_insufficient_history') == exp_insufficient and
        act.get('trajectory') == exp_traj and
        act.get('baseline_score') == exp_baseline and
        act.get('baseline_deviation') == exp_dev and
        (exp_forecast is None or act.get('forecast_14_days') == exp_forecast)
    )
    print(f"==> EXACT THEORETICAL MATCH: {match}\n")
