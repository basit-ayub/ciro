# CIRO — Crisis Intelligence & Response Orchestrator

CIRO is an advanced multi-agent crisis response system built for Pakistan. It leverages real-time signal intelligence, deep reasoning, and dynamic counterfactual simulation to orchestrate emergency responses 90% faster than traditional manual systems.

## 🚀 The Vision

During urban emergencies (flash floods, accidents, heatwaves), the first 30 minutes are critical. CIRO autonomously digests hundreds of fragmented signals (social media, weather data, CCTV, traffic) and converts them into actionable deployment plans for Rescue 1122, Edhi, and Police services. 

By utilizing a cinematic **Live Reasoning Stadium** in a Flutter mobile app, crisis operators can observe Gemini 3 AI agents thinking, planning, and acting in real-time.

## 🧠 System Architecture

CIRO is composed of a tri-agent architecture communicating over a real-time event bus:

1. **Sentinel (Agent 1):** Real-time anomaly detection using a fast keyword pre-filter and Gemini 3 Flash. Ingests 50+ signals/sec.
2. **Analyst (Agent 2):** Deep reasoning engine powered by Gemini 3 Pro (Thinking Mode). Synthesizes multimodal data (vision, text) into comprehensive Situation Artifacts.
3. **Commander (Agent 3):** Execution engine. Takes Situation Artifacts and generates a DAG (Directed Acyclic Graph) of response actions, executing them via 5 custom MCP tools.

## 🛠 Tech Stack

- **Backend:** Python, FastAPI, structlog
- **AI Models:** Google Gemini 3 Pro & Gemini 3 Flash
- **Agent Tooling:** Model Context Protocol (MCP) via FastMCP
- **State & Streaming:** Firebase Firestore, Server-Sent Events (SSE)
- **Mobile App:** Flutter 3.27, Riverpod, Google Maps SDK
- **Simulation:** NetworkX for counterfactual Twin Timelines
- **Integrations:** Twilio Voice/SMS, Google Maps Routes API

## 💥 Wow Factors

- **Hell Mode:** Trigger 5 simultaneous city-wide crises to watch the AI triage and prioritize in real-time.
- **Twin Timeline Simulator:** See the exact person-minutes saved by CIRO vs. traditional manual response.
- **Vision-First Citizen Reporting:** Upload photos and watch the Analyst agent instantly draw bounding boxes and assess severity.
- **Roman Urdu Mastery:** Push notifications to citizens are auto-translated into fluent, code-mixed Roman Urdu ("Bhaiyon, G-10 markaz mein flood hai...").
- **Voice Intake:** Twilio webhook integration to instantly transcribe panicked citizen phone calls into actionable intelligence.

## 📦 Getting Started

### Prerequisites
- Python 3.11+
- Flutter SDK (3.27+)
- Firebase Project configured
- API Keys: Gemini, Google Maps, Twilio (optional)

### Setup Backend
```bash
cd backend
python -m venv env
source env/bin/activate
pip install -r requirements.txt
cp .env.example .env # Add your API keys
fastapi run main.py
```

### Setup Mobile
```bash
cd mobile
flutter pub get
flutter run
```

## 📜 License
Apache 2.0
