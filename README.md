# Carevora – Flutter Web Application

**Compassionate Care, Smarter Tomorrow**  
AI-powered wellness monitoring and early risk detection system for elderly care homes.

---

## 🚀 Running the Web Application

### Development (CanvasKit - Default)
```bash
flutter run -d chrome
```

### Development with Specific Port (e.g. 52357 or 8080)
```bash
flutter run -d chrome --web-port=52357
```

### Production Build
```bash
flutter build web --release
```

### Build with Wasm (Skwasm Renderer)
```bash
flutter build web --wasm --release
```

---

## 🔑 Demo Login Credentials
- **Email**: `seetha@carevora.com`
- **Password**: `demo1234`

---

## 📱 Features & Target Screens Implemented

1. **Screen A – Login (`/login`)**:
   - 50/50 Desktop split layout with lavender-pink watercolor gradient, organic sparkles, leaf silhouettes, small-caps `CAREVORA` serif wordmark, caregiver hands illustration.
   - 36px radius white card with glow, SSO option, validation, and session persistence via SharedPreferences.
   - Mobile responsive: Compact header and full-width card.

2. **Screen B – Caregiver Dashboard Overview (`/dashboard`)**:
   - 260px Fixed Sidebar with active lavender pills, notification count badges, caregiver profile card ("Seetha N."), and log-out action.
   - Top greeting bar with live date chip and notifications bell.
   - Resident header card for *Mr. James Perera (ID: 9001)*.
   - 4 Multimodal Score Cards (Cognitive 0.64, Emotional 0.78, Metabolic 0.56, Overall 0.62 semicircle gauge).
   - Middle row: Risk Trend line chart (0.45, 0.50, 0.47, 0.55), Component Contribution Donut (40% purple, 35% red, 25% amber with brain icon), and Alerts & Notifications widget.
   - Recent Assessments table with color-coded risk pills and slide-up clinical inspection drawer.

3. **Screen C – Cognitive Assessment Live Session (`/dashboard/cognitive/session`)**:
   - Working 20-question clinical flow.
   - Speech-to-Text response capture and Text-to-Speech question readout with fallback.
   - Animated green microphone waveform (`VoiceWaveformWidget`).
   - Pastel city skyline illustration and AI Assistant protocol guidance dialogs.
   - Live session timer, progress ring, question checklist, and End Assessment scoring flow.

4. **Screen D – Marketing Landing Page (`/`)**:
   - Sticky navbar with smooth-scroll section links and auth actions.
   - Hero section with badge, typography ("Caring Today, Protecting Tomorrow"), and hands illustration.
   - Feature strip: AI Assistant, Smart Analysis, Risk Insights, Caregiver Support.
   - Purple trust banner with translucent accent icons.
   - Solutions and Contact sections.

5. **Sub-Pages**:
   - `/dashboard/residents`, `/dashboard/emotional`, `/dashboard/metabolic`, `/dashboard/alerts`, `/dashboard/reports`, `/dashboard/care-plans`, `/dashboard/settings`.
