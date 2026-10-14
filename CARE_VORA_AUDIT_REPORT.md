# Carevora: Final End-to-End Verification and System Audit Report

**Research Project Title:**  
*AI-Based Personalized Emotional Wellness, Social Isolation and Loneliness Trajectory Prediction System for Elderly Care Homes*  
**Academic / Research Specification:** IT23228108.pdf (Sections 3.1 – 3.5, Functional Requirements FR5 – FR8)  
**Verification Date:** October 2026  
**System Architecture:**
- **Frontend:** Flutter Mobile, Web & Desktop Client (`lib/`)
- **Backend:** Spring Boot 3.x REST API (`carevora-backend`, Port 8081)
- **AI Microservice:** Python 3.13 FastAPI (`carevora-ai-service`, Port 8000)
- **Latent Engine:** RALPA (Resident-Adaptive Longitudinal Prediction Algorithm)
- **Persistence Layer:** Spring Data JPA with H2 Database Engine

---

## 1. Executive Summary & Verification Evidence Matrix

All verification checks documented below reflect actual command outputs, terminal executions, and live HTTP requests executed against running instances of the application services.

| Verification Item | Status | Verification Performed | Observed Result | Relevant Files / Endpoints |
| :--- | :---: | :--- | :--- | :--- |
| **PyTorch Facial Emotion Inference** | **PASS** | Captured image bytes posted to FastAPI endpoint; CNN forward pass executed. | Trained `LightweightEmotionCNN` executed; emotion probabilities across 7 classes returned (`neutral: 25.2%`, `happy: 19.7%`, `sad: 21.9%`, etc.). | [vision_analyzer.py](file:///c:/Users/HP/Desktop/research/CAREVORA-J26-IT-421/carevora-ai-service/vision_analyzer.py)<br>`POST /api/ml/analyze-photo` |
| **Vocal Acoustic Feature Extraction** | **PASS** | 16kHz PCM audio sample sent to vocal pipeline. | Rule-based non-neural extraction computed (ZCR, RMS energy, pitch modulation: 0.95, cadence stability: 0.77, CREMA-D scale). | [audio_analyzer.py](file:///c:/Users/HP/Desktop/research/CAREVORA-J26-IT-421/carevora-ai-service/audio_analyzer.py)<br>`POST /api/ml/analyze-audio` |
| **RALPA Insufficient History Guard** | **PASS** | 0 and 1 historical session payloads sent to progression engine. | Suppressed premature forecast; returned `BASELINE_ESTABLISHING`, set `is_insufficient_history: true`, returned `forecast_14_days: null`. | [ralpa_engine.py](file:///c:/Users/HP/Desktop/research/CAREVORA-J26-IT-421/carevora-ai-service/ralpa_engine.py)<br>`POST /api/ml/predict-ralpa` |
| **RALPA Longitudinal Trajectory (2+ sessions)** | **PASS** | Evaluated 2 equal sessions, increasing scores, decreasing scores, stable series, and clamped out-of-range inputs. | Deterministic output; bounded in `[0.0, 100.0]`; valid 14-day continuous trajectory projected without NaN or Infinity. | [ralpa_engine.py](file:///c:/Users/HP/Desktop/research/CAREVORA-J26-IT-421/carevora-ai-service/ralpa_engine.py)<br>`POST /api/ml/predict-ralpa` |
| **Spring Boot -> FastAPI Bridge** | **PASS** | Authenticated call to `GET /api/ai/trajectory/{id}` with resident assessments from H2 DB. | Spring Boot fetched historical assessments, passed them to Python FastAPI on port 8000, and returned merged trajectory response (`HTTP 200`). | [AiMlService.java](file:///c:/Users/HP/Desktop/research/CAREVORA-J26-IT-421/carevora-backend/src/main/java/com/carevora/service/AiMlService.java)<br>`GET /api/ai/trajectory/1` |
| **Role-Based Access Control (RBAC)** | **PASS** | Authenticated test requests for Doctor, Caregiver Home 1, Caregiver Home 2, and Elder 1. | Doctor granted multi-facility view (`HTTP 200`); Cross-facility caregiver access and cross-resident elder access blocked with `HTTP 403 Forbidden`. | [ResidentService.java](file:///c:/Users/HP/Desktop/research/CAREVORA-J26-IT-421/carevora-backend/src/main/java/com/carevora/service/ResidentService.java)<br>`GET /api/residents/{id}` |
| **Assessment Submission & JPA Storage** | **PASS** | Assessment submission submitted via `POST /api/assessments/submit` and read back via `GET /api/assessments/resident/{id}`. | Assessment saved; score, contributing factors, and recommendations persisted; history query confirmed record created. | [AssessmentService.java](file:///c:/Users/HP/Desktop/research/CAREVORA-J26-IT-421/carevora-backend/src/main/java/com/carevora/service/AssessmentService.java)<br>`POST /api/assessments/submit` |
| **Database Persistence Across Process Restart** | **PARTIAL** | Inspected database configuration and persistence lifecycle across JVM restarts. | Runtime persistence across requests verified. However, H2 is configured as strictly **in-memory** (`jdbc:h2:mem:...`) and **does NOT survive JVM process restarts**. | [application.properties](file:///c:/Users/HP/Desktop/research/CAREVORA-J26-IT-421/carevora-backend/src/main/resources/application.properties) |
| **CORS and Network Configuration** | **PASS** | Inspected FastAPI and Spring Boot CORS headers and cross-origin permissions. | Wildcard `*` with credentials replaced with explicit origin patterns matching `localhost`, `127.0.0.1`, and Android emulator `10.0.2.2`. | [CorsConfig.java](file:///c:/Users/HP/Desktop/research/CAREVORA-J26-IT-421/carevora-backend/src/main/java/com/carevora/config/CorsConfig.java)<br>[main.py](file:///c:/Users/HP/Desktop/research/CAREVORA-J26-IT-421/carevora-ai-service/main.py) |
| **Flutter Frontend Integration & State Safety** | **PASS** | Verified resident switching, gallery photo picker, adaptive endpoints, and trajectory chart widget. | Transient image bytes cleared upon resident switch to avoid cross-contamination; 14-day trajectory displayed; 13 tests passed. | [emotional_wellness_page.dart](file:///c:/Users/HP/Desktop/research/CAREVORA-J26-IT-421/lib/features/assessment/presentation/emotional_wellness_page.dart)<br>[app_config.dart](file:///c:/Users/HP/Desktop/research/CAREVORA-J26-IT-421/lib/core/config/app_config.dart) |
| **Physical Hardware Capture** | **NOT TESTED** | Physical hardware camera sensor and microphone hardware recording on an actual physical Android/iOS device. | Live device hardware sensors cannot be tested in this headless environment; verified via byte payload processing and unit tests. | Mobile Hardware Sensors |

---

## 2. Complete Multimodal Workflow Verification

```
[Flutter Frontend]
  │  1. User selects resident -> clears prior transient bytes
  │  2. User uploads / captures photo & triggers assessment
  ▼
[Spring Boot Authenticated API (Port 8081)]
  │  3. JWT filter validates claims & user role
  │  4. ResidentService enforces facility boundary (403 if foreign facility)
  │  5. AssessmentService saves assessment, contributing factors, recommendations
  ▼
[H2 / JPA Persistence]
  │  6. Records written to assessments, assessment_answers, recommendations tables
  ▼
[AiMlService Bridge]
  │  7. Retrieves longitudinal history from AssessmentRepository
  │  8. POST http://127.0.0.1:8000/api/ml/predict-ralpa
  ▼
[Python FastAPI AI Microservice (Port 8000)]
  │  9. Vision: LightweightEmotionCNN (PyTorch FER-2013 weights)
  │ 10. Vocal: Rule-based acoustic extraction (CREMA-D scale)
  │ 11. RALPA Latent Progression Engine: Multimodal fusion + slope regression
  ▼
[Response to Flutter UI]
  │ 12. Returns baseline, deviation, and 14-day continuous risk trajectory
  │ 13. Renders trajectory chart card and personalized intervention actions
```

---

## 3. Database Persistence Findings

### Configuration Inspection
From [application.properties](file:///c:/Users/HP/Desktop/research/CAREVORA-J26-IT-421/carevora-backend/src/main/resources/application.properties):
```properties
spring.datasource.url=jdbc:h2:mem:carevora_db;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
spring.datasource.driverClassName=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.jpa.hibernate.ddl-auto=update
```

### Persistence Analysis
1. **Active Session Persistence**: Fully functional. Assessments submitted via `POST /api/assessments/submit` are immediately committed and queryable via `GET /api/assessments/resident/{residentId}`. In live test execution, Sarah Jenkins' assessment count increased from 1 to 2, and the bridge trajectory updated dynamically.
2. **Process Restart Persistence**: **Data disappears upon application shutdown**. The H2 database resides exclusively in RAM (`mem:carevora_db`). Upon application restart, all volatile records are lost, and [DataInitializer.java](file:///c:/Users/HP/Desktop/research/CAREVORA-J26-IT-421/carevora-backend/src/main/java/com/carevora/config/DataInitializer.java) reseeds the baseline initial dataset.
3. **Preservation Status**: The configuration was preserved as instructed. For future production readiness, changing `spring.datasource.url` to a file-based path (e.g. `jdbc:h2:file:./data/carevoradb`) or activating MySQL will enable cross-restart durability.

---

## 4. Role-Based Access Control (RBAC) Verification

Access control is enforced at the service layer in [ResidentService.java](file:///c:/Users/HP/Desktop/research/CAREVORA-J26-IT-421/carevora-backend/src/main/java/com/carevora/service/ResidentService.java), throwing `AccessDeniedException` which returns `HTTP 403 Forbidden`.

### Verified Test Cases:

| Actor | Role | Assigned Facility | Target Action | Status Code | Authorization Verdict |
| :--- | :--- | :--- | :--- | :---: | :---: |
| **Dr. Samantha Reed** | `DOCTOR` | Clinical Specialist (All facilities) | View Resident 1 (Serene Valley) | `HTTP 200` | **PASS (Authorized)** |
| **Dr. Samantha Reed** | `DOCTOR` | Clinical Specialist (All facilities) | View Resident 3 (Golden Sunset) | `HTTP 200` | **PASS (Authorized across homes)** |
| **Eleanor Vance** | `CAREGIVER` | Serene Valley Senior Living (Home 1) | View Resident 1 (Serene Valley) | `HTTP 200` | **PASS (Authorized in assigned facility)** |
| **Eleanor Vance** | `CAREGIVER` | Serene Valley Senior Living (Home 1) | View Resident 3 (Golden Sunset) | `HTTP 403` | **PASS (Blocked: Cross-facility forbidden)** |
| **David Silva** | `CAREGIVER` | Golden Sunset Eldercare (Home 2) | View Resident 3 (Golden Sunset) | `HTTP 200` | **PASS (Authorized in assigned facility)** |
| **David Silva** | `CAREGIVER` | Golden Sunset Eldercare (Home 2) | View Resident 1 (Serene Valley) | `HTTP 403` | **PASS (Blocked: Cross-facility forbidden)** |
| **Sarah Jenkins** | `ELDER` | Serene Valley Resident 1 | View Resident 1 (Self) | `HTTP 200` | **PASS (Authorized to view own record)** |
| **Sarah Jenkins** | `ELDER` | Serene Valley Resident 1 | View Resident 2 (Arthur, same home) | `HTTP 403` | **PASS (Blocked: Resident peer isolated)** |
| **Sarah Jenkins** | `ELDER` | Serene Valley Resident 1 | View Resident 3 (Margaret, other home) | `HTTP 403` | **PASS (Blocked: Cross-facility isolated)** |

---

## 5. RALPA Multi-Case Execution Results

Evaluated directly against `POST /api/ml/predict-ralpa` in [carevora-ai-service/tests/verify_live_system.py](file:///c:/Users/HP/Desktop/research/CAREVORA-J26-IT-421/carevora-ai-service/tests/verify_live_system.py):

### Case 1: Zero Historical Sessions (Initial Baseline Establishing)
- **Input:** `history_scores: []`, Questionnaire: 85.0, Social: 80.0
- **Observed:** `is_insufficient_history: True`, `trajectory: "BASELINE_ESTABLISHING"`, `forecast_14_days: null`
- **Verdict:** **PASS** (Prevents misleading early forecasts).

### Case 2: One Historical Session (Insufficient Longitudinal History)
- **Input:** `history_scores: [82.0]`, Questionnaire: 85.0, Social: 80.0
- **Observed:** `is_insufficient_history: True`, `trajectory: "BASELINE_ESTABLISHING"`, `forecast_14_days: null`
- **Verdict:** **PASS** (Requires minimum 2 sessions per RALPA Sec 3.1 specification).

### Case 3: Two Sessions with the Same Score (Stable Baseline)
- **Input:** `history_scores: [77.0, 77.0]`, Current wellness: 77.0
- **Observed:** Baseline: 23.0 risk, Deviation: 0.0, Slope: -0.0, `trajectory: "STABLE"`, `risk_level: "LOW"`
- **Forecast:** 14 points all steady at `[23.0, 23.0, 23.0, 23.0, ...]`
- **Verdict:** **PASS**.

### Case 4: Increasing Scores (Improving Wellness Trajectory)
- **Input:** `history_scores: [50.0, 60.0, 70.0, 80.0]`, Current wellness: 83.0 (risk 17.0)
- **Observed:** Baseline: 35.0 risk, Deviation: -18.0, Slope: -8.6, `trajectory: "IMPROVING"`
- **Forecast:** 14 points decreasing `[13.6, 10.1, 6.7, 3.2, 0.0, ...]`
- **Verdict:** **PASS**.

### Case 5: Decreasing Scores (Deteriorating Trajectory / Increasing Risk)
- **Input:** `history_scores: [85.0, 75.0, 65.0, 50.0]`, Current wellness: 49.8 (risk 50.2)
- **Observed:** Baseline: 31.2 risk, Deviation: +19.0, Slope: +9.54, `trajectory: "DETERIORATING"`, `risk_level: "MODERATE"`
- **Forecast:** 14 points increasing `[54.0, 57.8, 61.6, 65.5, ...]`
- **Verdict:** **PASS**.

### Case 6: Stable Scores Across Longitudinal Timepoints
- **Input:** `history_scores: [79.0, 80.0, 78.0, 81.0, 79.0]`, Current wellness: 76.2 (risk 23.8)
- **Observed:** Baseline: 20.6 risk, Deviation: +3.2, Slope: +0.4, `trajectory: "STABLE"`, `risk_level: "LOW"`
- **Forecast:** 14 points steady `[24.0, 24.1, 24.3, 24.4, ...]`
- **Verdict:** **PASS**.

### Case 7: Out-of-Range Negative & Overflow Clamping
- **Input:** `history_scores: [-100.0, 150.0, 85.0]`, Questionnaire: -45.0, Social: 250.0
- **Observed:** Clamped strictly to `[0.0, 100.0]`. No NaN, no Infinity, no unhandled exceptions.
- **Verdict:** **PASS**.

### Case 8: Missing, None, and Invalid Non-Numeric Values
- **Input:** `history_scores: [None, "invalid_val", 70.0, 72.0]`, Social: None
- **Observed:** Invalid elements sanitized, defaults applied safely, calculation completed (`HTTP 200`).
- **Verdict:** **PASS**.

### Case 9: Deterministic Execution
- **Verification:** Evaluated identical inputs twice in separate HTTP sessions.
- **Observed:** Output dictionaries matched 100% byte-for-byte (`True`).
- **Verdict:** **PASS**.

---

## 6. AI Endpoints & Modality Verification

### Facial Emotion Recognition
- **Endpoint:** `POST /api/ml/analyze-photo`
- **Metrics Endpoint:** `GET /api/ml/model-metrics`
- **Methodology:** Convolutional Neural Network forward pass on normalized 48x48 tensor.
- **Model Architecture:** `LightweightEmotionCNN` (3 Conv2D blocks with BatchNorm, MaxPool, ReLU, Dropout, and Linear classifier).
- **Model Weights & Checkpoint:** [emotion_model.pth](file:///c:/Users/HP/Desktop/research/CAREVORA-J26-IT-421/carevora-ai-service/emotion_model.pth) & [emotion_model_checkpoint.pth](file:///c:/Users/HP/Desktop/research/CAREVORA-J26-IT-421/carevora-ai-service/emotion_model_checkpoint.pth)
- **Saved Metrics JSON:** [model_metrics.json](file:///c:/Users/HP/Desktop/research/CAREVORA-J26-IT-421/carevora-ai-service/model_metrics.json)

#### Empirical Benchmark Accuracy (FER-2013 Dataset)
Evaluated across all **7,177 test samples** and **3,500 training samples** from the FER-2013 benchmark dataset:
- **Overall Test Accuracy:** **50.05%** (3,592 / 7,177 correct)
- **Overall Train Accuracy:** **50.91%** (1,782 / 3,500 correct)

| Emotion Class | Test Samples | Correct Predictions | Class Accuracy (%) | Precision | Recall | F1-Score |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Happy** | 1,774 | 1,444 | **81.40%** | 0.634 | 0.814 | **0.713** |
| **Surprise** | 831 | 528 | **63.54%** | 0.666 | 0.635 | **0.650** |
| **Neutral** | 1,233 | 698 | **56.61%** | 0.418 | 0.566 | **0.481** |
| **Sad** | 1,247 | 541 | **43.38%** | 0.391 | 0.434 | **0.411** |
| **Angry** | 957 | 290 | **30.30%** | 0.374 | 0.303 | **0.335** |
| **Fear** | 1,024 | 91 | **8.89%** | 0.326 | 0.089 | **0.140** |
| **Disgust** | 111 | 0 | **0.00%** | 0.000 | 0.000 | **0.000** |

- **Execution Sample Response:**
  ```json
  {
    "success": true,
    "filename": "test_face.jpg",
    "analysis": {
      "modality": "Facial Expression Analysis",
      "dominant_emotion": "neutral",
      "mood_summary": "NEUTRAL / CALM",
      "confidence": 0.25,
      "emotion_breakdown_percent": {
        "angry": 15.6,
        "disgust": 1.7,
        "fear": 12.7,
        "happy": 19.7,
        "neutral": 25.2,
        "sad": 21.9,
        "surprise": 3.1
      },
      "contributing_insight": "Live captured photo analysis indicates person is NEUTRAL / CALM with 25.2% confidence."
    }
  }
  ```

### Vocal Acoustic Analysis
- **Endpoint:** `POST /api/ml/analyze-audio`
- **Methodology:** **Rule-Based Acoustic Feature Extraction (Explicitly Non-Neural)**.
- **Acoustic Metrics:** Evaluates Zero-Crossing Rate (cadence/frication), Root-Mean-Square Energy (vocal power), and fundamental frequency modulation mapped against CREMA-D reference norms.
- **Execution Response:**
  ```json
  {
    "success": true,
    "filename": "voice_sample.wav",
    "analysis": {
      "modality": "Vocal Acoustic Analysis",
      "method": "Rule-Based Acoustic Feature Extraction (Non-Neural)",
      "grounding_dataset": "CREMA-D Normative Acoustic Scale",
      "acoustic_profile": "HAP",
      "profile_label": "Cheerful / High Valence",
      "vocal_wellness_score": 85.4,
      "metrics": {
        "pitch_modulation": 0.95,
        "cadence_stability": 0.77,
        "valence_estimate": 0.9
      },
      "clinical_disclaimer": "Acoustic observation only; not a diagnostic clinical speech classifier."
    }
  }
  ```

---

## 7. Frontend Flutter Integration

1. **Adaptive Networking ([app_config.dart](file:///c:/Users/HP/Desktop/research/CAREVORA-J26-IT-421/lib/core/config/app_config.dart))**:
   - Replaced hardcoded `localhost` references across auth, directory, and registration controllers.
   - Automatically resolves `10.0.2.2` on Android emulators and `localhost` / `127.0.0.1` on Web/Desktop.
2. **Resident State Isolation ([emotional_wellness_page.dart](file:///c:/Users/HP/Desktop/research/CAREVORA-J26-IT-421/lib/features/assessment/presentation/emotional_wellness_page.dart))**:
   - Switching between residents clears cached camera/photo bytes and refreshes affect state to prevent data leakage between residents.
3. **Gallery Upload Feature**:
   - Added `_pickImageFromGalleryOrFile` alongside camera capture, allowing photo evaluation on devices without physical cameras.
4. **Trajectory Chart Rendering**:
   - Renders 14-day continuous risk trajectory with safe fallback message when less than 2 sessions exist.
5. **Static Analysis & Test Results**:
   - `flutter analyze`: **0 errors**.
   - `flutter test`: **13/13 tests passed**.

---

## 8. Defect Fixes Summary

| ID | Component | Defect Description | Resolution Applied | Verification Status |
| :---: | :--- | :--- | :--- | :---: |
| **BUG-01** | `carevora-ai-service` | Wildcard CORS `allow_origins=["*"]` combined with `allow_credentials=True` violated W3C specification. | Replaced with regex `allow_origin_regex=r"^https?://(localhost\|127\.0\.0\.1\|10\.0\.2\.2)(:\d+)?$"`. | **VERIFIED** |
| **BUG-02** | `carevora-backend` | Spring Boot CORS used wildcard pattern with credentials. | Updated [CorsConfig.java](file:///c:/Users/HP/Desktop/research/CAREVORA-J26-IT-421/carevora-backend/src/main/java/com/carevora/config/CorsConfig.java) to explicitly permit `localhost`, `127.0.0.1`, and `10.0.2.2` via `setAllowedOriginPatterns`. | **VERIFIED** |
| **BUG-03** | `carevora-backend` | [AiMlService.java](file:///c:/Users/HP/Desktop/research/CAREVORA-J26-IT-421/carevora-backend/src/main/java/com/carevora/service/AiMlService.java) had no connection to actual database assessment records. | Injected `AssessmentRepository` and `ResidentRepository`, passing real longitudinal scores to Python. | **VERIFIED** |
| **BUG-04** | `carevora-ai-service` | Score domain mismatch: historical wellness scores (0-100) were regressed directly against risk scores (100-wellness), distorting slope calculations. | Added domain normalization in [ralpa_engine.py](file:///c:/Users/HP/Desktop/research/CAREVORA-J26-IT-421/carevora-ai-service/ralpa_engine.py) to map wellness history to risk scale. | **VERIFIED** |
| **BUG-05** | `carevora-ai-service` | Non-numeric or `None` values in history triggered Pydantic validation errors (`HTTP 422`). | Updated request model to `List[Any]` and added sanitization to handle `None`, NaN, and non-numeric inputs gracefully. | **VERIFIED** |
| **BUG-06** | Flutter UI | Selecting a new resident in the UI retained the previously captured photo bytes and affect score. | Added state cleanup on resident switch in [emotional_wellness_page.dart](file:///c:/Users/HP/Desktop/research/CAREVORA-J26-IT-421/lib/features/assessment/presentation/emotional_wellness_page.dart). | **VERIFIED** |
| **BUG-07** | Flutter UI | No gallery photo selection available, preventing photo testing on camera-less machines. | Implemented `_pickImageFromGalleryOrFile` using `image_picker`. | **VERIFIED** |

---

## 9. Remaining Risks and Research Disclaimers

> [!CAUTION]
> **Research Disclaimer & Clinical Boundaries**
> - **Not a Clinical Diagnostic Tool:** Carevora and the RALPA progression engine are designed for behavioral observation, proactive caregiver alerting, and wellness trajectory tracking. They are **not clinically validated** for diagnosing major depressive disorder (MDD), cognitive decline, or psychiatric illnesses.
> - **Demographic Domain Shift:** The PyTorch facial emotion model was trained on the public FER-2013 dataset (composed primarily of young-to-middle-aged adult images). Facial expressions in elderly individuals with age-related skin elasticity differences, resting muscle laxity, or neurological conditions may exhibit domain shift. Model confidence must be treated as indicative rather than diagnostic.
> - **Non-Neural Vocal Analysis:** The vocal modality extracts rule-based acoustic prosody metrics (pitch modulation, energy, cadence) and maps them to CREMA-D reference ranges. It is an acoustic observation tool, not a speech pathology or neural emotion classifier.

> [!WARNING]
> **H2 Database Volatility**
> - The H2 database is currently running in-memory (`jdbc:h2:mem:...`). All assessment submissions will be erased whenever the Spring Boot process stops. Production deployment must transition to persistent PostgreSQL, MySQL, or file-based H2.

---

## 10. Verification Commands

### Run Python AI Microservice Tests
```powershell
& "C:\Users\HP\AppData\Local\Programs\Python\Python313\python.exe" -m unittest carevora-ai-service/tests/test_ai_service.py
```
*(Result: 8 tests passed in 0.075s)*

### Run Comprehensive Live Verification Script
```powershell
& "C:\Users\HP\AppData\Local\Programs\Python\Python313\python.exe" carevora-ai-service/tests/verify_live_system.py
```
*(Result: Exited with code 0; all RBAC, persistence, and RALPA cases passed)*

### Run Spring Boot Backend Tests
```powershell
cd carevora-backend
.\gradlew.bat test
```
*(Result: `BUILD SUCCESSFUL in 29s`, all unit and integration tests passed)*

### Run Flutter Frontend Tests and Static Analysis
```powershell
flutter test
flutter analyze
```
*(Result: 13 tests passed; static analysis reported 0 errors)*
