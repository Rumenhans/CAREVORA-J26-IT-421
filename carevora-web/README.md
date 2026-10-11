# Carevora – AI-Powered Wellness Monitoring & Early Risk Detection System

> **Brand Tagline**: *"Compassionate Care, Smarter Tomorrow"*  
> AI-powered wellness monitoring and early risk detection system for elderly care homes.

---

## 1. Quick Start

### Prerequisites
- Node.js `v18+` or `v20+` (Tested on `v24.10.0`)
- npm `v9+` or `v11+`

### Installation & Running Locally
```bash
# Navigate to the web application directory
cd carevora-web

# Install dependencies
npm install

# Start development server
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

---

## 2. Demo Credentials

- **Email**: `seetha@carevora.com`
- **Password**: `demo1234`
- **Role**: Primary Caregiver (`Seetha N.`)
- **Primary Monitored Resident**: `Mr. James Perera` (ID: `9001`, Room `105`, Age `78`)

---

## 3. Implemented Routes & Screens

| Route | Screen Description | Faithful Reproduction Details |
| :--- | :--- | :--- |
| `/login` | **Screen A – Login** | 50/50 Desktop split. Left: Lavender watercolor gradient, organic sparkles, leaf silhouettes, custom SVG `<Logo />`, serif small-caps `CAREVORA`, heart divider, caregiver hands illustration. Right: 36px radius white card, 2px lavender border, verified form validation, SSO button, remember me. |
| `/dashboard` | **Screen B – Caregiver Overview** | 260px fixed sidebar, caregiver card (`Seetha N.`), live date chip, `Mr. James Perera` resident header, 4 score cards (Cognitive 0.64, Emotional 0.78, Metabolic 0.56, Overall 0.62 semicircle gauge), Risk Trend line chart (0.45, 0.50, 0.47, 0.55), Component Contribution Donut (40% / 35% / 25%), Alerts widget, Recent Assessments table + interactive slide-out **Assessment Detail Drawer**. |
| `/dashboard/cognitive/session` | **Screen C – Cognitive Live Session** | Live 20-question clinical flow for Mr. James Perera. Large lavender question card with Web Speech TTS read-aloud button, pastel city skyline SVG, AI guidance bubble, animated green audio waveform with microphone toggle, 0–100% progress ring, and interactive 20-question checklist overview. Completing an assessment updates Recent Assessments. |
| `/` | **Screen D – Marketing Landing Page** | Sticky navigation bar, hero with badge, H1 typography ("Caring Today, Protecting Tomorrow"), CTA buttons, arch-masked visual with placeholder at `/public/images/hero-caregiver.jpg`, 4-item feature strip, and purple gradient trust band. |
| `/dashboard/residents` | **Residents Directory** | Multimodal resident cards directory with risk badges. |
| `/dashboard/alerts` | **Alerts Center** | Full-fidelity notification list with risk tags and timestamps. |
| `/dashboard/settings` | **Caregiver Settings** | Accessibility toggles, font size preferences, speech parameters, and privacy compliance overview. |

---

## 4. Mobile & PWA Responsiveness (< 768px)

- **Bottom Tab Bar**: Fixed bottom navigation bar with 5 items (*Overview*, *Residents*, *Assess*, *Alerts*, *More*).
- **Slide-In Drawer**: Full navigation access via the *More* trigger.
- **Card Stacking**: Tables transform automatically into readable mobile cards.
- **PWA Ready**: Configured `manifest.json` with primary brand color `#6C3FC5`.

---

## 5. How to Swap Mock Data for a Real API

The application uses typed interfaces in `lib/mock-data.ts`. To connect to a live backend (e.g. Spring Boot / FastAPI):

1. **Replace mock data imports**:
   ```typescript
   // Currently:
   import { mockResident, mockRecentAssessments } from "@/lib/mock-data";

   // Replace with an API client:
   const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/residents/9001`);
   const resident = await res.json();
   ```
2. **Add environment variables**:
   Create a `.env.local` file:
   ```env
   NEXT_PUBLIC_API_URL=http://localhost:8080
   ```
3. **Connect Auth**:
   Replace the simulated `localStorage` session check in `app/login/page.tsx` with your JWT cookie or session handler.
