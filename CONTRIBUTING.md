# Contributing to VibeReel

Thank you for your interest in contributing to **VibeReel**! VibeReel is built to production standards using clean architecture principles, robust test coverage, and strict static analysis.

---

## 🛠️ Monorepo Workflow & Structure

VibeReel is organized as a monorepo:
- `mobile/`: Flutter mobile application (Android & iOS).
- `backend/`: FastAPI backend with SQLAlchemy & PostgreSQL.
- `docs/`: Technical specifications, DB schema documentation, and setup guides.

---

## 📋 General Guidelines

1. **Branching Naming Convention**:
   - `feature/feature-name` (e.g. `feature/video-duets`)
   - `fix/issue-name` (e.g. `fix/jwt-expiration-handling`)
   - `docs/doc-name` (e.g. `docs/architecture-update`)
2. **Commit Message Format**:
   Follow Conventional Commits format:
   - `feat: add video bookmarking support`
   - `fix: resolve race condition in forum comment upvoting`
   - `docs: update API specification for moderation`

---

## 🐍 Backend Guidelines (`/backend`)

1. **Coding Style**:
   - We enforce strict linting and formatting via **Ruff**:
     ```bash
     venv/bin/ruff check .
     ```
   - We enforce strict static typing via **Mypy**:
     ```bash
     venv/bin/mypy app tests
     ```
2. **Testing Standards**:
   - Write comprehensive Pytest specs under `backend/tests/`.
   - Run tests before pushing:
     ```bash
     venv/bin/pytest
     ```
3. **Database Migrations**:
   - When modifying SQLAlchemy models in `app/models/`, generate Alembic migrations:
     ```bash
     venv/bin/alembic revision --autogenerate -m "Add new table"
     venv/bin/alembic upgrade head
     ```

---

## 📱 Mobile Guidelines (`/mobile`)

1. **State Management & Architecture**:
   - Follow MVVM pattern using **Riverpod** (`StateNotifier` / `Provider`).
   - Keep business logic inside ViewModels and repository classes.
   - Do NOT place direct API calls or business logic inside UI Widgets.
2. **Static Analysis & Tests**:
   - Ensure zero warnings or errors from `flutter analyze`:
     ```bash
     flutter analyze
     ```
   - Run widget and unit tests:
     ```bash
     flutter test
     ```

---

## ✅ Pull Request Checklist

Before submitting a Pull Request, verify:
- [ ] Backend tests pass (`venv/bin/pytest`) with 100% pass rate.
- [ ] Backend code passes Ruff (`venv/bin/ruff check .`) and Mypy (`venv/bin/mypy app tests`).
- [ ] Flutter static analysis (`flutter analyze`) returns `No issues found!`.
- [ ] Flutter unit/widget tests (`flutter test`) pass completely.
- [ ] Documentation is updated for any new endpoints or features.
