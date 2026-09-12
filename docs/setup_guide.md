# VibeReel Developer Setup Guide

This guide walks you through setting up the VibeReel full-stack project locally for development and testing.

---

## 📋 Prerequisites

Ensure the following tools are installed on your machine:
- **Python**: 3.10 or later (`python3 --version`)
- **Flutter**: 3.x with Dart 3.x (`flutter --version`)
- **PostgreSQL**: 14+ (or Docker for database containerization)
- **Git**

---

## 🐍 1. Backend Setup (`backend/`)

### Step 1: Create Virtual Environment
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
```

### Step 2: Install Dependencies
```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### Step 3: Configure Environment Variables
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

Edit `.env` to match your local database credentials:
```env
DATABASE_URL=postgresql://vibereel:vibereel@localhost:5432/vibereel_db
ASYNC_DATABASE_URL=postgresql+asyncpg://vibereel:vibereel@localhost:5432/vibereel_db
SECRET_KEY=dev_secret_key_change_me_in_production_123456789
ENVIRONMENT=development
```

### Step 4: Run Database Migrations
```bash
alembic upgrade head
```

### Step 5: Start FastAPI Server
```bash
uvicorn app.main:app --reload --port 8000
```
Access swagger docs at [http://localhost:8000/docs](http://localhost:8000/docs).

---

## 📱 2. Mobile Setup (`mobile/`)

### Step 1: Install Dependencies
```bash
cd mobile
flutter pub get
```

### Step 2: Run Static Analysis
```bash
flutter analyze
```

### Step 3: Launch Mobile App
Launch iOS Simulator or Android Emulator and run:
```bash
flutter run
```

---

## 🧪 3. Verification & Testing

### Run Backend Unit Tests
```bash
cd backend
pytest
```

### Run Mobile Unit Tests
```bash
cd mobile
flutter test
```
