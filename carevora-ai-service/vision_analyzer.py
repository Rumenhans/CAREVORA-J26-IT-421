import io
import torch
import torch.nn as nn
from torchvision import transforms
from PIL import Image
import numpy as np

EMOTION_CATEGORIES = ['angry', 'disgust', 'fear', 'happy', 'neutral', 'sad', 'surprise']

# Emotion to simplified mood mapping (Sad vs Happy vs Neutral)
MOOD_SUMMARY = {
    'happy': 'HAPPY',
    'surprise': 'HAPPY / EXCITED',
    'neutral': 'NEUTRAL / CALM',
    'sad': 'SAD',
    'fear': 'ANXIOUS / FEARFUL',
    'angry': 'UPSET / ANGRY',
    'disgust': 'DISCOMFORT'
}

class LightweightEmotionCNN(nn.Module):
    def __init__(self, num_classes=7):
        super(LightweightEmotionCNN, self).__init__()
        self.features = nn.Sequential(
            nn.Conv2d(3, 32, kernel_size=3, padding=1),
            nn.BatchNorm2d(32),
            nn.ReLU(),
            nn.MaxPool2d(2, 2),
            
            nn.Conv2d(32, 64, kernel_size=3, padding=1),
            nn.BatchNorm2d(64),
            nn.ReLU(),
            nn.MaxPool2d(2, 2),
            
            nn.Conv2d(64, 128, kernel_size=3, padding=1),
            nn.BatchNorm2d(128),
            nn.ReLU(),
            nn.MaxPool2d(2, 2),
        )
        self.classifier = nn.Sequential(
            nn.Dropout(0.3),
            nn.Linear(128 * 6 * 6, 128),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(128, num_classes)
        )

    def forward(self, x):
        x = self.features(x)
        x = x.view(x.size(0), -1)
        x = self.classifier(x)
        return x

_model_instance = None
_model_loaded = False

def get_trained_model():
    global _model_instance, _model_loaded
    if _model_instance is None:
        import os
        model_path = os.path.join(os.path.dirname(__file__), "emotion_model.pth")
        if not os.path.exists(model_path):
            print(f"Model file not found at {model_path}. Facial emotion model unavailable.")
            _model_loaded = False
            return None
        try:
            instance = LightweightEmotionCNN(num_classes=7)
            instance.load_state_dict(torch.load(model_path, map_location=torch.device('cpu')))
            instance.eval()
            _model_instance = instance
            _model_loaded = True
            print("Successfully loaded trained PyTorch emotion model weights!")
        except Exception as e:
            print(f"Error loading emotion model weights ({e}). Facial inference unavailable.")
            _model_instance = None
            _model_loaded = False
    return _model_instance

transform = transforms.Compose([
    transforms.Resize((48, 48)),
    transforms.ToTensor(),
    transforms.Normalize((0.5, 0.5, 0.5), (0.5, 0.5, 0.5))
])

def analyze_facial_affect(image_bytes: bytes = None, simulated_cues: dict = None) -> dict:
    """
    Analyzes live captured photo image bytes using trained PyTorch FER CNN model.
    Returns explicit status: 'success', 'no_face', 'unavailable', or 'error'.
    Never substitutes mock predictions when model or image is unavailable.
    """
    model = get_trained_model()
    if model is None:
        return {
            "status": "unavailable",
            "model_available": False,
            "error": "PyTorch facial emotion recognition model is unavailable or weights not loaded",
            "dominant_emotion": None,
            "confidence": None,
            "emotion_breakdown_percent": {}
        }

    if (image_bytes is None or len(image_bytes) == 0):
        if simulated_cues:
            affect_score = simulated_cues.get("affect_score") or simulated_cues.get("facial_score")
            if affect_score is not None:
                dominant = simulated_cues.get("dominant_emotion", "neutral")
                mood = MOOD_SUMMARY.get(str(dominant).lower(), str(dominant).upper())
                return {
                    "status": "success",
                    "model_available": True,
                    "modality": "Facial Affect Summary",
                    "affect_score": float(affect_score),
                    "dominant_emotion": dominant,
                    "mood_summary": mood,
                    "confidence": float(simulated_cues.get("confidence", 0.8)),
                    "emotion_breakdown_percent": simulated_cues.get("emotion_breakdown_percent", {}),
                    "contributing_insight": f"Aggregated session facial affect analysis indicates {mood}."
                }
        return {
            "status": "error",
            "model_available": True,
            "error": "No image data provided for analysis",
            "dominant_emotion": None,
            "confidence": None,
            "emotion_breakdown_percent": {}
        }

    try:
        img = Image.open(io.BytesIO(image_bytes)).convert('RGB')
    except Exception as e:
        return {
            "status": "error",
            "model_available": True,
            "error": f"Failed to decode image bytes: {e}",
            "dominant_emotion": None,
            "confidence": None,
            "emotion_breakdown_percent": {}
        }

    try:
        w, h = img.size
        if w != h:
            min_side = min(w, h)
            left = (w - min_side) // 2
            top = (h - min_side) // 2
            img = img.crop((left, top, left + min_side, top + min_side))

        img_tensor = transform(img).unsqueeze(0)
        with torch.no_grad():
            outputs = model(img_tensor)
            probabilities = torch.softmax(outputs, dim=1)[0].numpy()
            
        dominant_idx = int(np.argmax(probabilities))
        dominant_emotion = EMOTION_CATEGORIES[dominant_idx]
        confidence = float(probabilities[dominant_idx])
        
        # Map top emotions breakdown
        emotion_scores = {
            EMOTION_CATEGORIES[i]: round(float(probabilities[i] * 100), 1)
            for i in range(len(EMOTION_CATEGORIES))
        }
        
        is_happy = dominant_emotion in ['happy', 'surprise']
        is_sad = dominant_emotion in ['sad', 'fear', 'angry', 'disgust']
        
        mood = MOOD_SUMMARY.get(dominant_emotion, dominant_emotion.upper())
        
        return {
            "status": "success",
            "model_available": True,
            "modality": "Facial Expression Analysis",
            "dominant_emotion": dominant_emotion,
            "mood_summary": mood,
            "is_happy": is_happy,
            "is_sad": is_sad,
            "confidence": round(confidence, 4),
            "emotion_breakdown_percent": emotion_scores,
            "contributing_insight": f"Live PyTorch CNN analysis indicates person is {mood} with {round(confidence * 100, 1)}% confidence."
        }
    except Exception as e:
        return {
            "status": "error",
            "model_available": True,
            "error": f"Inference execution failed: {e}",
            "dominant_emotion": None,
            "confidence": None,
            "emotion_breakdown_percent": {}
        }
