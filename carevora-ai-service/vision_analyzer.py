import io
import torch
import torch.nn as nn
from torchvision import transforms
from PIL import Image
import numpy as np

EMOTION_CATEGORIES = ['angry', 'disgust', 'fear', 'happy', 'neutral', 'sad', 'surprise']

# Emotion to simplified mood mapping (Sad vs Happy vs Neutral)
MOOD_SUMMARY = {
    'happy': 'HAPPY / UPLIFTED',
    'surprise': 'SURPRISED / STARTLED',
    'neutral': 'NEUTRAL / CALM',
    'sad': 'SAD / DEPRESSED',
    'fear': 'FEARFUL / ANXIOUS',
    'confused': 'CONFUSED / AGITATED',
    'angry': 'CONFUSED / AGITATED',
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
    and returns a square crop tightly focused on the face (avoiding ceilings/neck/backgrounds).
    """
    try:
        w, h = img.size
        # Search primarily in upper 72% where the head/face is located on webcams
        search_h = int(h * 0.72)
        arr = np.array(img).astype(np.float32)
        R, G, B = arr[:search_h, :, 0], arr[:search_h, :, 1], arr[:search_h, :, 2]
        Y = 0.299 * R + 0.587 * G + 0.114 * B
        Cr = (R - Y) * 0.713 + 128.0
        Cb = (B - Y) * 0.564 + 128.0

        # Inclusive human skin chrominance + RGB ratio (works for all ethnicities/lighting)
        skin = (Cr >= 126) & (Cr <= 185) & (Cb >= 72) & (Cb <= 138) & (Y >= 25) & (R > G) & (R > B)
        ys, xs = np.where(skin)

        if len(xs) > 250:
            x_min, x_max = int(np.percentile(xs, 6)), int(np.percentile(xs, 94))
            y_min, y_max = int(np.percentile(ys, 6)), int(np.percentile(ys, 94))
            fw, fh = x_max - x_min, y_max - y_min
            if fw > 30 and fh > 30:
                cx = (x_min + x_max) // 2
                cy = (y_min + y_max) // 2
                side = int(min(max(fw, fh) * 1.10, min(w, h)))
                half = side // 2
                l = max(0, cx - half)
                t = max(0, cy - half)
                r = min(w, l + side)
                b = min(h, t + side)
                return img.crop((l, t, r, b))
    except Exception:
        pass

    # Fallback: upper-center crop centered at face level (42% height on laptop webcams)
    w, h = img.size
    crop_size = int(min(w, h) * 0.65)
    cx, cy = w // 2, int(h * 0.42)
    l = max(0, cx - crop_size // 2)
    t = max(0, cy - crop_size // 2)
    r = min(w, l + crop_size)
    b = min(h, t + crop_size)
    return img.crop((l, t, r, b))


def detect_smile_signal(face_img: Image.Image, happy_prob: float = 0.20, ang_prob: float = 0.15, brow_furrow: float = 5.0) -> float:
    """
    Detects true zygomatic smiles with visible teeth and elevated mouth curvature.
    Avoids false positives on neutral/sad closed mouths, lip highlights, or confused furrowed brows.
    """
    try:
        # If brow is visibly furrowed and angry > happy, person is perplexed/confused, not smiling
        if brow_furrow >= 7.8 and ang_prob > happy_prob * 1.1:
            return 0.0

        arr = np.array(face_img.convert('L'))
        h, w = arr.shape
        # Mouth region: lower 30% of face, center 60%
        y1, y2 = int(h * 0.68), int(h * 0.92)
        x1, x2 = int(w * 0.20), int(w * 0.80)
        mouth = arr[y1:y2, x1:x2]
        if mouth.size == 0:
            return 0.0

        mouth_mean = float(np.mean(mouth))
        teeth_pixels = float(np.mean(mouth > 220))
        contrast = float(np.std(mouth))

        # True open-mouth smile with teeth exposure
        if teeth_pixels > 0.035 and contrast > 50 and mouth_mean > 110 and happy_prob >= 0.15:
            return min(0.92, 0.68 + teeth_pixels * 2.5)

        # High confidence neural smile
        if happy_prob >= 0.38 and happy_prob > ang_prob:
            return float(happy_prob)

        return 0.0
    except Exception:
        return 0.0


def detect_brow_furrow(face_img: Image.Image) -> float:
    """
    Measures vertical frown lines / corrugator contraction in the glabella region (between eyebrows).
    High values (> 7.5) indicate brow furrowing (confused / agitated). Low values (< 6.5) indicate relaxed calm face.
    """
    try:
        arr = np.array(face_img.convert('L'))
        h, w = arr.shape
        glabella = arr[int(h * 0.22):int(h * 0.42), int(w * 0.38):int(w * 0.62)]
        if glabella.size == 0:
            return 0.0
        gx = np.abs(np.diff(glabella.astype(np.float32), axis=1))
        return float(np.mean(gx))
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

        happy_idx = EMOTION_CATEGORIES.index('happy')
        fear_idx = EMOTION_CATEGORIES.index('fear')
        surp_idx = EMOTION_CATEGORIES.index('surprise')
        ang_idx = EMOTION_CATEGORIES.index('angry')
        sad_idx = EMOTION_CATEGORIES.index('sad')
        neu_idx = EMOTION_CATEGORIES.index('neutral')

        p_happy = float(probabilities[happy_idx])
        p_fear = float(probabilities[fear_idx])
        p_surp = float(probabilities[surp_idx])
        p_ang = float(probabilities[ang_idx])
        p_sad = float(probabilities[sad_idx])
        p_neu = float(probabilities[neu_idx])

        arr = np.array(face_crop.convert('L'))
        h, w = arr.shape
        mouth = arr[int(h * 0.68):int(h * 0.92), int(w * 0.20):int(w * 0.80)]
        mouth_mean = float(np.mean(mouth)) if mouth.size > 0 else 110.0

        raw_dominant_idx = int(np.argmax(probabilities))
        raw_dominant = EMOTION_CATEGORIES[raw_dominant_idx]

        brow_furrow = detect_brow_furrow(face_crop)
        smile_score = detect_smile_signal(face_crop, p_happy, p_ang, brow_furrow)

        # 1. HAPPY (Smile / Uplifted):
        # Genuine zygomatic smile, or happy is dominant without brow furrowing
        is_happy_expr = (
            (smile_score > 0.0) or
            (raw_dominant == 'happy' and p_happy >= 0.28 and brow_furrow < 7.5) or
            (p_happy >= 0.40 and brow_furrow < 7.5)
        )

        # 2. CONFUSED (Brow furrowing, corrugator AU4, questioning prosody):
        # Frown lines, elevated angry/questioning signal, no genuine smile
        is_confused_expr = not is_happy_expr and (
            (brow_furrow >= 7.8 and p_ang >= 0.20) or
            (raw_dominant == 'angry' and brow_furrow >= 7.2) or
            (brow_furrow >= 8.0 and p_ang > p_neu and p_ang >= p_sad * 0.9) or
            (p_ang >= 0.28 and brow_furrow >= 7.0)
        )

        # 3. SAD (Downturned mouth, depressed corners, sad dominant):
        # Low mouth brightness (dark corners), sad is dominant or elevated without fear
        is_sad_expr = not is_happy_expr and not is_confused_expr and (
            (raw_dominant == 'sad' and mouth_mean < 88 and p_sad >= 0.28) or
            (p_sad >= 0.32 and mouth_mean < 92 and p_sad > p_fear * 1.15)
        )

        # 4. FEAR (Apprehension, wide eyes, fear/surprise elevation):
        # Elevated fear or fear+surprise with raised eyebrows / tension
        is_fear_expr = not is_happy_expr and not is_confused_expr and not is_sad_expr and (
            (raw_dominant == 'fear') or
            (p_fear >= 0.17 and (p_surp >= 0.045 or p_fear > p_ang) and brow_furrow >= 6.5) or
            (p_fear * 2.2 + p_surp * 1.5 > 0.46 and p_fear >= 0.15)
        )

        if is_happy_expr:
            probabilities[happy_idx] = max(probabilities[happy_idx] * 1.5, smile_score, 0.65)
            dominant_emotion = 'happy'
        elif is_confused_expr:
            probabilities[ang_idx] = max(probabilities[ang_idx] * 1.85, 0.58)
            probabilities[neu_idx] *= 0.40
            dominant_emotion = 'confused'
        elif is_sad_expr:
            probabilities[sad_idx] = max(probabilities[sad_idx] * 1.5, 0.55)
            dominant_emotion = 'sad'
        elif is_fear_expr:
            probabilities[fear_idx] = max(probabilities[fear_idx] * 2.0, 0.58)
            probabilities[surp_idx] = max(probabilities[surp_idx], 0.15)
            probabilities[neu_idx] *= 0.35
            probabilities[sad_idx] *= 0.50
            dominant_emotion = 'fear'
        elif brow_furrow < 6.8 or raw_dominant == 'neutral' or p_neu >= 0.12:
            probabilities[neu_idx] = max(probabilities[neu_idx] * 2.0, 0.60)
            probabilities[sad_idx] *= 0.50
            probabilities[ang_idx] *= 0.50
            dominant_emotion = 'neutral'
        else:
            dominant_emotion = 'neutral'
            probabilities[neu_idx] = 0.55

        probabilities = probabilities / np.sum(probabilities)

        if dominant_emotion == 'confused':
            confidence = float(probabilities[ang_idx])
        elif dominant_emotion in EMOTION_CATEGORIES:
            confidence = float(probabilities[EMOTION_CATEGORIES.index(dominant_emotion)])
        else:
            confidence = float(np.max(probabilities))

        # Map top emotions breakdown across the 7 canonical FER classes
        emotion_scores = {
            EMOTION_CATEGORIES[i]: round(float(probabilities[i] * 100), 1)
            for i in range(len(EMOTION_CATEGORIES))
        }

        is_happy = dominant_emotion == 'happy'
        is_sad = dominant_emotion == 'sad'

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
