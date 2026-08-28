# Tandurust

An AI-powered integrated care-access and quality support platform to streamline patient prioritization, improve healthcare accessibility, and ensure continuity of care in rural and underserved areas.

**Smart India Hackathon 2026 | PS ID: 26133**
**Organization:** Government of Maharashtra | Maharashtra State Innovation Society

---

## Problem Statement

Rural and underserved communities face long travel distances, shortages of specialists, irregular diagnostics, fragmented medical records, delayed referrals, and limited awareness of available services. The challenge is to improve timely access, continuity, quality, and accountability while strengthening the public-health system.

---

## Solution Overview

Tandurust is a comprehensive digital health platform that connects patients, doctors, ASHA workers, and healthcare facilities through an integrated mobile application with AI-powered triage, teleconsultation, and interoperable health records.

---

## Key Features

### Core Healthcare Services
- **AI-Powered Digital Triage (ESI)** - TensorFlow Lite ML model for Emergency Severity Index classification
- **Symptom Checker** - Offline heuristic-based symptom analysis with ranked condition matching
- **Teleconsultation** - Remote video/audio consultation bridging rural patients to specialists
- **OPD Queue Management** - Token-based queue with real-time wait-time estimation

### Continuity of Care
- **Longitudinal Patient Records (EHR)** - Complete medical history across facilities (Sub-Centre to District Hospital)
- **Referral Tracking** - End-to-end referral management between PHC, CHC, and District Hospital
- **ABDM/ABHA Integration** - National Health ID with FHIR R4 interoperable records and consent management
- **Diagnostic Coordination** - Lab test ordering, tracking, and result management

### Community Health
- **ASHA Worker Dashboard** - Daily tasks, patient registration, follow-up reminders for frontline workers
- **High-Risk Patient Follow-up** - Maternal, child, and chronic condition monitoring with overdue alerts
- **Community Help** - Patient-volunteer connection platform

### Facility Management
- **Facility Dashboard** - Real-time metrics: bed occupancy, doctor availability, medicine stock, equipment status
- **Medicine Availability** - Facility-wise stock visibility and alerts
- **Appointment Management** - Doctor scheduling and queue optimization

### Accessibility & Support
- **Multilingual Support** - English, Hindi, Punjabi (extensible)
- **Voice Navigation** - Speech-to-text commands on every screen for accessibility
- **AI Chatbot (RADHA)** - Personal health assistant with text-to-speech
- **First Aid AI** - Step-by-step emergency instructions with offline fallback
- **Emergency Escalation** - One-tap emergency calls (108/112)
- **Low-Connectivity Design** - Offline-first features with background sync

### Additional Features
- **Blood Bank** - Blood availability and linking
- **Government Schemes** - Healthcare scheme information
- **Health Tips & News** - Health awareness content
- **Pandemic Emergency Mode** - Outbreak response for doctors
- **Doctor Rating System** - Patient feedback mechanism

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) - Cross-platform (Android, iOS, Web) |
| Backend | Python Flask + SQLAlchemy |
| Database | SQLite (dev) / PostgreSQL (prod) |
| ML Model | TensorFlow Lite (ESI triage classification) |
| AI/NLP | OpenRouter API (GPT-4o-mini) |
| Health Standards | ABDM/ABHA, FHIR R4 |
| Speech | speech_to_text + flutter_tts |
| Localization | easy_localization |

---

## User Roles

1. **Patient** - Book appointments, check symptoms, view records, teleconsult, track referrals
2. **Doctor** - Manage appointments, triage patients, prescribe, refer, monitor high-risk cases
3. **ASHA Worker** - Register patients, conduct follow-ups, manage community health tasks

---

## Getting Started

### Prerequisites
- Flutter SDK ^3.5.3
- Python 3.9+
- pip

### Frontend Setup
```bash
flutter pub get
flutter run
```

### Backend Setup
```bash
cd backend
pip install -r requirements.txt
python app.py
```

---

## Architecture

```
Patient/ASHA (Mobile App)
        |
   Flutter Frontend
        |
   Flask REST API
        |
   ┌────┴────┐
   |         |
SQLAlchemy  TFLite ML
(Database)  (Triage Model)
```

**Facility Hierarchy:** Sub-Centre → PHC → CHC → Rural Hospital → District Hospital

---

## Expected Outcomes (aligned with PS 26133)

- Reduced travel and waiting time through teleconsultation and queue management
- Earlier consultation via AI triage and symptom checking
- Improved referral completion with end-to-end tracking
- Better follow-up for maternal, child, and chronic conditions
- Improved medicine/diagnostic availability visibility
- Enhanced quality monitoring through facility dashboards
- Continuity of care through interoperable longitudinal health records

---

## Team

Built for Smart India Hackathon 2026
