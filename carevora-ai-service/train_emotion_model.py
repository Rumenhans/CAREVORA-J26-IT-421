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

# 7 FER-2013 categories mapped to indices
EMOTIONS = ['angry', 'disgust', 'fear', 'happy', 'neutral', 'sad', 'surprise']
LABEL_MAP = {emotion: i for i, emotion in enumerate(EMOTIONS)}

class FERZipDataset(Dataset):
    def __init__(self, zip_path, split='train', transform=None):
        self.zip_path = zip_path
        self.split = split
        self.transform = transform
        self.samples = []
        
        with zipfile.ZipFile(self.zip_path, 'r') as z:
            for name in z.namelist():
                parts = name.split('/')
                if len(parts) >= 3 and parts[0] == split and parts[1] in LABEL_MAP:
                    if name.endswith('.jpg') or name.endswith('.png'):
                        self.samples.append((name, LABEL_MAP[parts[1]]))
                        
        print(f"Loaded {len(self.samples)} images for split: {split}")

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        filename, label = self.samples[idx]
        with zipfile.ZipFile(self.zip_path, 'r') as z:
            img_bytes = z.read(filename)
            img = Image.open(io.BytesIO(img_bytes)).convert('RGB')
            
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
            nn.MaxPool2d(2, 2), # 48x48 -> 24x24
            
            nn.Conv2d(32, 64, kernel_size=3, padding=1),
            nn.BatchNorm2d(64),
            nn.ReLU(),
            nn.MaxPool2d(2, 2), # 24x24 -> 12x12
            
            nn.Conv2d(64, 128, kernel_size=3, padding=1),
            nn.BatchNorm2d(128),
            nn.ReLU(),
            nn.MaxPool2d(2, 2), # 12x12 -> 6x6
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

def train_model(epochs=3, batch_size=64):
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

    train_dataset = FERZipDataset(ZIP_PATH, split='train', transform=transform_train)
    test_dataset = FERZipDataset(ZIP_PATH, split='test', transform=transform_test)
    
    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True, num_workers=0)
    test_loader = DataLoader(test_dataset, batch_size=batch_size, shuffle=False, num_workers=0)

    model = LightweightEmotionCNN(num_classes=7).to(device)
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.parameters(), lr=0.001)

    print("Starting Model Training...")
    for epoch in range(epochs):
        model.train()
        running_loss = 0.0
        correct = 0
        total = 0
        
        for i, (images, labels) in enumerate(train_loader):
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
            
            if (i + 1) % 100 == 0:
                print(f"Epoch [{epoch+1}/{epochs}], Step [{i+1}/{len(train_loader)}], Loss: {loss.item():.4f}, Acc: {100.*correct/total:.2f}%")

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

        print(f"Epoch [{epoch+1}/{epochs}] Completed - Train Acc: {100.*correct/total:.2f}%, Test Acc: {100.*test_correct/test_total:.2f}%")

    # Save trained PyTorch model weights
    torch.save(model.state_dict(), MODEL_SAVE_PATH)
    print(f"Model successfully saved to {MODEL_SAVE_PATH}")

if __name__ == "__main__":
    train_model(epochs=2, batch_size=64)
