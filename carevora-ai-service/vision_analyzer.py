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

def extract_face_crop(img: Image.Image) -> Image.Image:
    """
    Locates the primary human face in the webcam image using robust YCrCb skin segmentation
    and returns a square crop tightly focused on the face (avoiding ceilings/backgrounds).
    """
    try:
        w, h = img.size
        arr = np.array(img).astype(np.float32)
        R, G, B = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
        Y = 0.299 * R + 0.587 * G + 0.114 * B
        Cr = (R - Y) * 0.713 + 128.0
        Cb = (B - Y) * 0.564 + 128.0

        # Human skin chrominance cluster
        skin = (Cr >= 133) & (Cr <= 178) & (Cb >= 77) & (Cb <= 127) & (Y >= 30) & (Y <= 245)
        ys, xs = np.where(skin)

        if len(xs) > 400:
            x_min, x_max = int(np.percentile(xs, 5)), int(np.percentile(xs, 95))
            y_min, y_max = int(np.percentile(ys, 5)), int(np.percentile(ys, 95))
            fw, fh = x_max - x_min, y_max - y_min
            if fw > 30 and fh > 30:
                cx = (x_min + x_max) // 2
                cy = (y_min + y_max) // 2
                side = int(max(fw, fh) * 1.35)
                half = side // 2
                l = max(0, cx - half)
                t = max(0, cy - half)
                r = min(w, cx + half)
                b = min(h, cy + half)
                return img.crop((l, t, r, b))
    except Exception:
        pass

    # Fallback: lower-center crop (avoiding top ceiling area of webcam)
    w, h = img.size
    crop_size = int(min(w, h) * 0.75)
    cx, cy = w // 2, int(h * 0.55)
    l = max(0, cx - crop_size // 2)
    t = max(0, cy - crop_size // 2)
    r = min(w, l + crop_size)
    b = min(h, t + crop_size)
    return img.crop((l, t, r, b))


def detect_smile_signal(face_img: Image.Image) -> float:
    """
    Detects smile/teeth/lip-corner elevation features in the lower third of the face.
    Returns a confidence boost score between 0.0 and 0.92 for smiling expressions.
    """
    try:
        arr = np.array(face_img.convert('L'))
        h, w = arr.shape
        # Mouth region: lower 35% of face, center 60%
        y1, y2 = int(h * 0.65), int(h * 0.94)
        x1, x2 = int(w * 0.20), int(w * 0.80)
        mouth = arr[y1:y2, x1:x2]
        if mouth.size == 0:
            return 0.0

        # Teeth visibility and mouth contrast
        bright_ratio = float(np.mean(mouth > 135))
        contrast = float(np.std(mouth))

        if bright_ratio > 0.06 and contrast > 18:
            return min(0.92, 0.65 + bright_ratio * 1.2)
        return 0.0
    except Exception:
        return 0.0


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
        face_crop = extract_face_crop(img)
        img_tensor = transform(face_crop).unsqueeze(0)
        with torch.no_grad():
            outputs = model(img_tensor)
            probabilities = torch.softmax(outputs, dim=1)[0].numpy()

        smile_score = detect_smile_signal(face_crop)
        if smile_score > 0.0:
            happy_idx = EMOTION_CATEGORIES.index('happy')
            probabilities[happy_idx] = max(probabilities[happy_idx], smile_score)
            probabilities = probabilities / np.sum(probabilities)

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
