from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from vision_analyzer import analyze_facial_affect
from audio_analyzer import analyze_vocal_affect
from ralpa_engine import RALPAEngine

app = FastAPI(
    title="CAREVORA AI/ML Microservice",
    description="Multimodal Emotion Recognition & RALPA Trajectory Forecasting Engine (FER-2013 & PyTorch CNN Grounded)",
    version="1.0.0"
)

# Enable CORS for Flutter Web & Mobile Clients (localhost, 127.0.0.1, and Android emulators)
# Avoiding wildcard allow_origins=["*"] with allow_credentials=True to comply with CORS specification
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1|10\.0\.2\.2)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

ralpa = RALPAEngine()

class MultimodalAssessmentRequest(BaseModel):
    resident_id: int
    questionnaire_score: float = 85.0
    facial_cues: Optional[Dict[str, Any]] = None
    vocal_cues: Optional[Dict[str, Any]] = None
    social_score: Optional[float] = 80.0
    history_scores: Optional[List[Any]] = None
    score_domain: Optional[str] = "wellness"

@app.get("/")
def root():
    return {
        "status": "online",
        "service": "CAREVORA AI/ML Intelligence Microservice",
        "models": {
            "facial": "Trained PyTorch FER-2013 CNN Model",
            "vocal": "CREMA-D Acoustic Feature Pipeline",
            "trajectory": "RALPA Latent Progression Engine"
        }
    }

@app.post("/api/ml/analyze-photo")
async def analyze_photo(file: UploadFile = File(...)):
    """
    Endpoint to receive a live captured photo from mobile/web camera,
    process it through trained PyTorch FER model, and return whether person is HAPPY or SAD.
    """
    contents = await file.read()
    res = analyze_facial_affect(image_bytes=contents)
    return {
        "success": True,
        "filename": file.filename,
        "analysis": res
    }

@app.post("/api/ml/analyze-audio")
async def analyze_audio(file: UploadFile = File(...)):
    """
    Endpoint for acoustic speech feature extraction from recorded audio file/bytes.
    Explicitly non-neural; calculates rule-based zero crossings, RMS energy, and cadence metrics.
    """
    contents = await file.read()
    res = analyze_vocal_affect(audio_bytes=contents)
    return {
        "success": True,
        "filename": file.filename,
        "analysis": res
    }

@app.post("/api/ml/predict-ralpa")
def predict_ralpa_progression(req: MultimodalAssessmentRequest):
    # 1. Vision Emotion Inference
    face_res = analyze_facial_affect(simulated_cues=req.facial_cues)
    
    # 2. Audio Acoustic Inference
    audio_res = analyze_vocal_affect(simulated_cues=req.vocal_cues)

    # 3. Multimodal Latent Fusion & RALPA Trajectory Progression
    scores = {
        'questionnaire': req.questionnaire_score,
        'facial': face_res.get('affect_score', 80.0),
        'vocal': audio_res['vocal_wellness_score'],
        'social': req.social_score or 80.0
    }

    prediction = ralpa.predict_progression(
        resident_id=req.resident_id,
        current_scores=scores,
        history_scores=req.history_scores,
        score_domain=req.score_domain or "wellness"
    )

    return {
        "success": True,
        "data": {
            **prediction,
            "modality_breakdown": {
                "facial": face_res,
                "vocal": audio_res
            }
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
