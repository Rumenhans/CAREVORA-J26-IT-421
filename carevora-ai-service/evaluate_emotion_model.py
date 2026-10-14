import os
import sys
import zipfile
import io
import json
import time
import torch
import torch.nn as nn
from torchvision import transforms
from PIL import Image
import numpy as np

# Add service directory to path
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)

from vision_analyzer import LightweightEmotionCNN

ZIP_PATH = r"C:\Users\HP\Downloads\archive (1).zip"
MODEL_PATH = os.path.join(current_dir, "emotion_model.pth")
METRICS_JSON_PATH = os.path.join(current_dir, "model_metrics.json")
CHECKPOINT_PATH = os.path.join(current_dir, "emotion_model_checkpoint.pth")

EMOTIONS = ['angry', 'disgust', 'fear', 'happy', 'neutral', 'sad', 'surprise']
LABEL_MAP = {e: i for i, e in enumerate(EMOTIONS)}

transform_test = transforms.Compose([
    transforms.Resize((48, 48)),
    transforms.ToTensor(),
    transforms.Normalize((0.5, 0.5, 0.5), (0.5, 0.5, 0.5))
])

def evaluate():
    print("="*75)
    print("EVALUATING CAREVORA FACIAL EMOTION MODEL ACCURACY ON FER-2013 DATASET")
    print("="*75)
    
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f"Using device: {device}")
    
    # 1. Load Model
    model = LightweightEmotionCNN(num_classes=7).to(device)
    state_dict = torch.load(MODEL_PATH, map_location=device)
    model.load_state_dict(state_dict)
    model.eval()
    print("PyTorch LightweightEmotionCNN successfully loaded from emotion_model.pth")
    
    # 2. Extract Test Samples from Zip
    test_samples = []
    train_samples = []
    print(f"Reading dataset index from {ZIP_PATH}...")
    with zipfile.ZipFile(ZIP_PATH, 'r') as z:
        for name in z.namelist():
            parts = name.split('/')
            if len(parts) >= 4 and parts[0] == 'images1' and (name.endswith('.jpg') or name.endswith('.png')):
                split = parts[1]
                emotion = parts[2]
                if emotion in LABEL_MAP:
                    if split == 'test':
                        test_samples.append((name, LABEL_MAP[emotion]))
                    elif split == 'train':
                        train_samples.append((name, LABEL_MAP[emotion]))

    print(f"Found {len(test_samples)} Test Images and {len(train_samples)} Train Images.")
    
    # Evaluate Test Set
    print("\n--- Evaluating Complete Test Set (7,177 images) ---")
    test_correct = 0
    test_total = 0
    class_correct = {i: 0 for i in range(7)}
    class_total = {i: 0 for i in range(7)}
    confusion_matrix = np.zeros((7, 7), dtype=int)
    
    batch_size = 128
    t0 = time.time()
    
    with zipfile.ZipFile(ZIP_PATH, 'r') as z:
        for start_idx in range(0, len(test_samples), batch_size):
            batch_items = test_samples[start_idx:start_idx + batch_size]
            tensors = []
            labels = []
            for fname, lbl in batch_items:
                img_bytes = z.read(fname)
                img = Image.open(io.BytesIO(img_bytes)).convert('RGB')
                tensors.append(transform_test(img))
                labels.append(lbl)
                
            batch_tensor = torch.stack(tensors).to(device)
            batch_labels = torch.tensor(labels).to(device)
            
            with torch.no_grad():
                outputs = model(batch_tensor)
                _, preds = outputs.max(1)
                
            test_total += len(labels)
            correct_mask = preds.eq(batch_labels)
            test_correct += correct_mask.sum().item()
            
            for p, l in zip(preds.cpu().numpy(), labels):
                confusion_matrix[l][p] += 1
                class_total[l] += 1
                if p == l:
                    class_correct[l] += 1
                    
            if (start_idx // batch_size + 1) % 15 == 0 or start_idx + batch_size >= len(test_samples):
                elapsed = time.time() - t0
                pct = (test_total / len(test_samples)) * 100
                print(f"Progress: {test_total}/{len(test_samples)} ({pct:.1f}%) | Current Acc: {100.0 * test_correct / test_total:.2f}% | Elapsed: {elapsed:.1f}s")

    test_accuracy = round(100.0 * test_correct / test_total, 2)
    print(f"\n===> FINAL TEST ACCURACY: {test_accuracy}% ({test_correct}/{test_total})")

    # Evaluate Sample of Train Set (3,500 samples for fast reliable train metric)
    print("\n--- Evaluating Training Split Sample (3,500 images) ---")
    np.random.seed(42)
    train_subset_indices = np.random.choice(len(train_samples), size=min(3500, len(train_samples)), replace=False)
    train_subset = [train_samples[i] for i in train_subset_indices]
    
    train_correct = 0
    train_total = 0
    with zipfile.ZipFile(ZIP_PATH, 'r') as z:
        for start_idx in range(0, len(train_subset), batch_size):
            batch_items = train_subset[start_idx:start_idx + batch_size]
            tensors = []
            labels = []
            for fname, lbl in batch_items:
                img_bytes = z.read(fname)
                img = Image.open(io.BytesIO(img_bytes)).convert('RGB')
                tensors.append(transform_test(img))
                labels.append(lbl)
                
            batch_tensor = torch.stack(tensors).to(device)
            batch_labels = torch.tensor(labels).to(device)
            
            with torch.no_grad():
                outputs = model(batch_tensor)
                _, preds = outputs.max(1)
                
            train_total += len(labels)
            train_correct += preds.eq(batch_labels).sum().item()
            
    train_accuracy = round(100.0 * train_correct / train_total, 2)
    print(f"===> ESTIMATED TRAINING ACCURACY: {train_accuracy}% ({train_correct}/{train_total})")

    # Per-Class Metrics Calculation
    class_metrics = {}
    print("\n--- PER-CLASS PERFORMANCE BREAKDOWN ---")
    print(f"{'Emotion Class':<12} | {'Samples':<8} | {'Correct':<8} | {'Accuracy':<10} | {'Precision':<10} | {'Recall':<10} | {'F1-Score':<10}")
    print("-" * 80)
    for i, emotion in enumerate(EMOTIONS):
        tp = confusion_matrix[i][i]
        fp = np.sum(confusion_matrix[:, i]) - tp
        fn = np.sum(confusion_matrix[i, :]) - tp
        total_cls = class_total[i]
        acc = round(100.0 * tp / max(total_cls, 1), 2)
        prec = round(tp / max(tp + fp, 1), 3)
        rec = round(tp / max(tp + fn, 1), 3)
        f1 = round(2 * (prec * rec) / max(prec + rec, 1e-6), 3)
        
        class_metrics[emotion] = {
            "samples": int(total_cls),
            "correct": int(tp),
            "accuracy_percent": float(acc),
            "precision": float(prec),
            "recall": float(rec),
            "f1_score": float(f1)
        }
        print(f"{emotion:<12} | {total_cls:<8} | {tp:<8} | {acc:<10.2f}% | {prec:<10.3f} | {rec:<10.3f} | {f1:<10.3f}")

    # Build Metrics JSON Payload
    results_payload = {
        "model_architecture": "LightweightEmotionCNN (3-stage Conv2D + BatchNorm + Dropout + Linear)",
        "dataset": "FER-2013 (Facial Expression Recognition 2013)",
        "resolution": "48x48 RGB",
        "num_classes": 7,
        "classes": EMOTIONS,
        "metrics": {
            "test_accuracy_percent": float(test_accuracy),
            "train_accuracy_percent": float(train_accuracy),
            "total_test_samples": int(test_total),
            "total_train_samples_evaluated": int(train_total),
            "class_breakdown": class_metrics,
            "confusion_matrix": confusion_matrix.tolist()
        },
        "evaluation_timestamp": time.strftime("%Y-%m-%d %H:%M:%S")
    }

    # 1. Save to model_metrics.json
    with open(METRICS_JSON_PATH, "w") as f:
        json.dump(results_payload, f, indent=2)
    print(f"\n[OK] Model accuracy & metrics saved to: {METRICS_JSON_PATH}")

    # 2. Save complete checkpoint containing state_dict + metrics dictionary
    checkpoint = {
        "model_state_dict": state_dict,
        "test_accuracy": test_accuracy,
        "train_accuracy": train_accuracy,
        "class_metrics": class_metrics,
        "dataset": "FER-2013",
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S")
    }
    torch.save(checkpoint, CHECKPOINT_PATH)
    print(f"[OK] Checkpoint with embedded metrics saved to: {CHECKPOINT_PATH}")

if __name__ == "__main__":
    evaluate()
