<div align="center">

# 🤝 Contributing to Ondes HOST

First off — **thank you** for taking the time to contribute! 🎉  
Whether you're fixing a typo, hunting a bug, or shipping an entire feature, you're making Ondes HOST better for everyone.

</div>

---

## 📋 Table of Contents

- [Code of Conduct](#-code-of-conduct)
- [Ways to Contribute](#-ways-to-contribute)
- [Project Structure](#-project-structure)
- [Development Setup](#-development-setup)
- [Making Changes](#-making-changes)
- [Commit Convention](#-commit-convention)
- [Pull Request Checklist](#-pull-request-checklist)
- [Reporting Bugs](#-reporting-bugs)
- [Requesting Features](#-requesting-features)
- [Adding Screenshots](#-adding-screenshots)

---

## 🌊 Code of Conduct

Be kind. Be constructive. Be patient. We're all here to build something useful together.  
Discrimination, harassment, or bad-faith behaviour of any kind will not be tolerated.

---

## 🧩 Ways to Contribute

You don't have to write code to contribute! Here are some ideas:

| Type | Examples |
|---|---|
| 🐛 **Bug reports** | Something crashes? Behaves unexpectedly? Open an issue. |
| 💡 **Feature requests** | Got a cool idea? Let's discuss it in an issue first. |
| 🛠️ **Code** | Fix a bug, implement a feature, improve performance. |
| 📸 **Screenshots** | Take screenshots of the app running locally and submit them. |
| 📖 **Documentation** | Improve the README, add usage examples, fix typos. |
| 🌍 **Translation** | Help translate the UI strings to other languages. |
| ⭐ **Star the repo** | Low-effort but genuinely helps! |

---

## 🗂️ Project Structure

```
ondes-host/
├── api/                       # Django 5 backend
│   ├── apps/
│   │   ├── authentication/    # JWT auth
│   │   ├── docker_manager/    # Docker SDK wrapper + WebSocket metrics
│   │   ├── github_integration/# OAuth 2.0 flow, repo browser
│   │   ├── nginx_manager/     # Vhost CRUD, Certbot, DNS check
│   │   ├── ssh_manager/       # WebSocket SSH (Paramiko)
│   │   └── stacks/            # Full deploy pipeline, webhooks
│   └── config/                # Django settings, ASGI, root URLs
├── app/                       # Flutter frontend (macOS + web)
│   └── lib/
│       ├── main.dart
│       ├── screens/           # One file per screen
│       ├── providers/         # State management (Provider)
│       ├── services/          # API clients, WebSocket helpers
│       ├── theme/             # App theme & colours
│       ├── utils/             # Shared helpers
│       └── widgets/           # Reusable UI components
├── nginx/                     # Platform-level NGINX config
├── .github/
│   └── screenshots/           # ← Put your screenshots here!
├── docker-compose.yml
├── deploy.sh
└── .env.example
```

---

## 🛠️ Development Setup

### Prerequisites

| Tool | Minimum version |
|---|---|
| Python | 3.11+ |
| Flutter SDK | 3.43+ |
| Docker Desktop | 24+ |
| Git | any recent version |

### Backend (Django/Daphne)

```bash
cd api
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# Apply migrations (SQLite used automatically in dev — no Postgres needed)
python manage.py migrate

# Start the dev server (HTTP only)
python manage.py runserver

# Or with full WebSocket support (recommended):
daphne -b 0.0.0.0 -p 8000 config.asgi:application
```

The API will be available at `http://localhost:8000/api/`.

### Frontend — macOS desktop

```bash
cd app
flutter pub get
flutter run -d macos
```

### Frontend — web (Chrome)

```bash
cd app
flutter run -d chrome \
  --dart-define=API_URL=http://localhost:8000/api \
  --dart-define=WS_URL=ws://localhost:8000
```

### Full stack with Docker Compose

```bash
cp .env.example .env
# Edit .env — change SECRET_KEY and POSTGRES_PASSWORD at minimum
docker-compose up --build
```

| Service | URL |
|---|---|
| Frontend | http://localhost:3000 |
| API | http://localhost:8000/api/ |
| Admin | http://localhost:8000/admin/ |

---

## ✏️ Making Changes

1. **Fork** the repository and clone your fork locally.

```bash
git clone https://github.com/<your-username>/ONDES_HOST.git
cd ONDES_HOST
```

2. **Create a branch** — use a descriptive name:

```bash
# Bug fix
git checkout -b fix/nginx-vhost-delete-crash

# New feature
git checkout -b feat/stack-resource-limits

# Documentation
git checkout -b docs/update-migration-guide
```

3. **Make your changes** — keep PRs focused. One thing per PR.

4. **Test locally**:

```bash
# Backend — run Django checks
cd api && python manage.py check

# Backend — run migrations check
python manage.py migrate --check

# Flutter — analyze code
cd app && flutter analyze

# Flutter — run tests
flutter test
```

5. **Commit** following the convention below.

6. **Push** and open a Pull Request.

---

## 📝 Commit Convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short summary>
```

| Type | When to use |
|---|---|
| `feat` | A new feature |
| `fix` | A bug fix |
| `docs` | Documentation only changes |
| `style` | Formatting, missing semicolons — no logic change |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf` | Performance improvement |
| `test` | Adding or fixing tests |
| `chore` | Build process, dependency updates |

**Examples:**

```
feat(stacks): add resource limits (CPU/memory) to deploy form
fix(nginx): prevent double-reload on vhost delete
docs(readme): add screenshot placeholders
chore(deps): bump django to 5.1.2
```

---

## ✅ Pull Request Checklist

Before submitting, make sure:

- [ ] My branch is up to date with `main`
- [ ] I've tested the change locally (backend + frontend if applicable)
- [ ] `flutter analyze` passes with no new warnings
- [ ] `python manage.py check` passes
- [ ] I haven't committed `.env`, secrets, or local config files
- [ ] The PR description explains **what** changed and **why**
- [ ] I've linked the related issue (if any) with `Closes #123`

---

## 🐛 Reporting Bugs

Please include:

1. **What happened** — describe the problem clearly.
2. **Steps to reproduce** — numbered list.
3. **Expected behaviour** — what should have happened.
4. **Environment** — OS, Flutter version, Python version, Docker version.
5. **Logs** — paste relevant logs (redact any secrets!).
6. **Screenshots** — if the bug is visual.

> Open a bug report at [github.com/MartinBellot/ONDES_HOST/issues](https://github.com/MartinBellot/ONDES_HOST/issues).

---

## 💡 Requesting Features

Before opening a feature request:

- Search existing issues — it might already be planned.
- If it's a big change, open a **discussion** first to get early feedback.

When opening a request, describe:
- The **problem** you're trying to solve (not just the solution).
- How you imagine the feature working.
- Whether you'd like to implement it yourself.

---

## 📸 Adding Screenshots

Screenshots in the README make a huge difference — both for first-time visitors and for search indexing. Here's how to contribute them:

1. Run the app locally (see [Development Setup](#-development-setup)).
2. Take clean screenshots of:
   - The **Dashboard** (container overview)
   - The **GitHub** repo browser
   - A **Stack Deploy** in progress (with live logs)
   - The **Domaine & SSL** tab
   - The **Infrastructure Canvas**
   - The **SSH Terminal**
3. Save them as PNG, named exactly like the placeholders in the README:
   - `.github/screenshots/dashboard.png`
   - `.github/screenshots/github.png`
   - `.github/screenshots/deploy_logs.png`
   - `.github/screenshots/ssl.png`
   - `.github/screenshots/canvas.png`
   - `.github/screenshots/ssh.png`
4. Include them in your PR with the title `docs: add app screenshots`.

> 💡 **Tip:** Use macOS's `⌘ + Shift + 4` for precise region captures. Aim for 1400–1600 px wide.

---

## 🙏 Thank You

Every contribution matters. If you're unsure about anything, just open an issue or a draft PR and ask — we're happy to help!

<div align="center">

**[ondes.pro](https://ondes.pro)** · [Open an issue](https://github.com/MartinBellot/ONDES_HOST/issues)

</div>
