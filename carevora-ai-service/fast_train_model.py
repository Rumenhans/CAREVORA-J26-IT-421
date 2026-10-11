import os
import zipfile
import io
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
from torchvision import transforms
from PIL import Image

ZIP_PATH = r"C:\Users\HP\Downloads\archive (7) (1).zip"
MODEL_SAVE_PATH = r"d:\pratice\Akka\carevora-ai-service\emotion_model.pth"

EMOTIONS = ['angry', 'disgust', 'fear', 'happy', 'neutral', 'sad', 'surprise']
LABEL_MAP = {emotion: i for i, emotion in enumerate(EMOTIONS)}

class FastInMemoryFERDataset(Dataset):
    def __init__(self, zip_path, split='train', max_per_class=800, transform=None):
        self.transform = transform
        self.images = []
        self.labels = []
        
        print(f"Loading {split} split into RAM for fast training...")
        with zipfile.ZipFile(zip_path, 'r') as z:
            class_counts = {e: 0 for e in EMOTIONS}
            for name in z.namelist():
                parts = name.split('/')
                if len(parts) >= 3 and parts[0] == split and parts[1] in LABEL_MAP:
                    emotion = parts[1]
                    if class_counts[emotion] < max_per_class:
                        if name.endswith('.jpg') or name.endswith('.png'):
                            img_bytes = z.read(name)
                            img = Image.open(io.BytesIO(img_bytes)).convert('RGB')
                            self.images.append(img)
                            self.labels.append(LABEL_MAP[emotion])
                            class_counts[emotion] += 1
                            
        print(f"Successfully cached {len(self.images)} images in RAM for {split} split!")

    def __len__(self):
        return len(self.images)

    def __getitem__(self, idx):
        img = self.images[idx]
        label = self.labels[idx]
        if self.transform:
            img = self.transform(img)
        return img, label

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

def run_fast_training(epochs=5, batch_size=32):
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f"Using compute device: {device}")
    
    transform_train = transforms.Compose([
        transforms.Resize((48, 48)),
        transforms.RandomHorizontalFlip(),
        transforms.ToTensor(),
        transforms.Normalize((0.5, 0.5, 0.5), (0.5, 0.5, 0.5))
    ])
    
    transform_test = transforms.Compose([
        transforms.Resize((48, 48)),
        transforms.ToTensor(),
        transforms.Normalize((0.5, 0.5, 0.5), (0.5, 0.5, 0.5))
    ])

    train_dataset = FastInMemoryFERDataset(ZIP_PATH, split='train', max_per_class=700, transform=transform_train)
    test_dataset = FastInMemoryFERDataset(ZIP_PATH, split='test', max_per_class=200, transform=transform_test)
    
    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
    test_loader = DataLoader(test_dataset, batch_size=batch_size, shuffle=False)

    model = LightweightEmotionCNN(num_classes=7).to(device)
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.parameters(), lr=0.001)

    print("Training PyTorch Emotion Model...")
    for epoch in range(epochs):
        model.train()
        running_loss = 0.0
        correct = 0
        total = 0
        
        for images, labels in train_loader:
            images, labels = images.to(device), labels.to(device)
            
            optimizer.zero_grad()
            outputs = model(images)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()
            
            running_loss += loss.item()
            _, predicted = outputs.max(1)
            total += labels.size(0)
            correct += predicted.eq(labels).sum().item()

        # Evaluate on Test Set
        model.eval()
        test_correct = 0
        test_total = 0
        with torch.no_grad():
            for images, labels in test_loader:
                images, labels = images.to(device), labels.to(device)
                outputs = model(images)
                _, predicted = outputs.max(1)
                test_total += labels.size(0)
                test_correct += predicted.eq(labels).sum().item()

        print(f"Epoch [{epoch+1}/{epochs}] - Train Acc: {100.*correct/total:.2f}%, Test Acc: {100.*test_correct/test_total:.2f}%")

    # Save PyTorch trained model weights
    torch.save(model.state_dict(), MODEL_SAVE_PATH)
    print(f"MODEL SUCCESSFULLY SAVED TO {MODEL_SAVE_PATH}")

if __name__ == "__main__":
    run_fast_training(epochs=4, batch_size=32)
