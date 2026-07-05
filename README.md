# CANARY - VERSION 1

CANARY is a local, browser-based AI testing and chat workbench built with Flask. VERSION 1 includes an overview dashboard, AI Chat, Auto Jailbreak, AI Bug Report Builder, transcript logs, and a rules/scope page.

The app is designed for people who want a private local interface for testing, chatting with, and comparing OpenRouter models without sending API keys through a hosted frontend. You run the server on your own machine, paste your own OpenRouter key once, pick a section, choose a model, and work locally.

> **Early version warning:** CANARY VERSION 1 is an early release. Expect rough edges, occasional UI issues, model endpoint failures, dependency/setup problems, and changing OpenRouter model availability. If something breaks, check the troubleshooting section below first.

> CANARY is intended for authorized AI testing, research, prompt experimentation, and personal model evaluation. Only test systems, prompts, data, and workflows you own or have permission to use.

---

## Features

- Local Flask web app
- Dark red CANARY dashboard UI
- Overview dashboard
- AI Chat tab
- Auto Jailbreak tab for authorized model red-team sessions
- AI Bug Report Builder tab
- Transcripts / logs tab
- Rules and scope tab
- OpenRouter API key support
- Shared API key field across the app
- Wide OpenRouter model dropdowns in Auto and Bug Report
- Custom OpenRouter model ID support where available
- Persistent per-session chat history
- Editable system message per AI Chat session
- Streaming responses
- Markdown rendering
- Code block rendering and copy buttons
- Credits/token-style usage counter
- Local JSONL transcript logs
- Built-in legal / scope reminder page
- Responsive layout for smaller screens

---

## Visible sections

CANARY VERSION 1 contains these main sidebar sections:

| Section | What it is for |
| --- | --- |
| Overview | Dashboard, status, quick access, and workspace activity. |
| Auto Jailbreak | Authorized model red-team runs using helper, target, and judge models. |
| Bug report | AI bug bounty/report drafting with builder and evaluator models. |
| AI Chat | Direct chat with the selected OpenRouter model route. |
| Transcripts | Local saved chat/report logs. |
| Rules | Scope, authorization, legality, and responsible-use reminders. |

---

## Current model support

VERSION 1 uses OpenRouter for model access. Different CANARY sections expose different model choices:

- **AI Chat** currently defaults to Mistral-family OpenRouter models.
- **Auto Jailbreak** uses helper, target, and judge model dropdowns with a wider OpenRouter list.
- **AI Bug Report Builder** uses builder and evaluator dropdowns with the same wider OpenRouter list.
- **Custom OpenRouter model IDs** are available in the wider model sections when the dropdown supports custom input.

The wider OpenRouter dropdown includes options such as:

- Claude / Anthropic routes, including Opus and Sonnet options
- GLM / Z.AI routes
- DeepSeek routes
- Sakana Fugu Ultra
- Kimi / Moonshot routes where configured
- Mistral / Mixtral routes
- GPT routes through OpenRouter where configured

Model availability depends on OpenRouter and your account/key. If a model disappears, returns a 404, or says no endpoint is available, choose another model or paste a custom OpenRouter model ID that is currently live.

### AI Chat defaults

Default AI Chat model list:

- `mistralai/mistral-large-2512`
- `mistralai/ministral-14b-2512`
- `mistralai/ministral-8b-2512`
- `mistralai/ministral-3b-2512`
- `mistralai/mistral-small-3.1-24b-instruct`
- `mistralai/mistral-small-24b-instruct-2501`
- `mistralai/mistral-large-2407`
- `mistralai/mistral-large`
- `mistralai/mistral-nemo`
- `mistralai/mixtral-8x22b-instruct`

Custom model IDs are allowed in AI Chat, but the current AI Chat route expects Mistral-family IDs that start with:

```text
mistralai/
```

If one Mistral endpoint is unavailable, CANARY attempts a Mistral-family fallback where configured.

---

## Requirements

- Windows, macOS, or Linux
- Python 3.10+
- An OpenRouter API key
- A modern browser

Create an OpenRouter key here:

```text
https://openrouter.ai/settings/keys
```

---

## Quick start on Windows PowerShell

From the project folder:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe app.py
```

Then open:

```text
http://127.0.0.1:5000
```

If the app is already installed and you only want to start it:

```powershell
.\.venv\Scripts\python.exe app.py
```

---

## Quick start on macOS / Linux

```bash
python3 -m venv .venv
./.venv/bin/python -m pip install --upgrade pip
./.venv/bin/python -m pip install -r requirements.txt
./.venv/bin/python app.py
```

Then open:

```text
http://127.0.0.1:5000
```

---

## How to use CANARY

1. Start the local server.
2. Open `http://127.0.0.1:5000`.
3. Accept the local-use terms gate.
4. Paste your OpenRouter key into the shared key field.
5. Choose a section:
   - **Overview** for the dashboard
   - **AI Chat** for normal chat
   - **Auto Jailbreak** for authorized model red-team runs
   - **Bug report** for AI bug bounty/report drafting
   - **Transcripts** for saved logs
   - **Rules** for scope and legal reminders
6. Pick the model/options for that section.
7. Click the section's start/connect button.
8. Send messages or paste a bug brief normally.

The selected API key, system message, and chat history stay active for the session until you reset or restart the app.

---

## Main screens

### Overview

The landing dashboard.

Includes:

- CANARY status
- quick access buttons
- workspace activity cards
- local/session indicators

### Auto Jailbreak

An authorized AI red-team workspace for running a target model against helper and judge models.

Includes:

- helper / target / judge model dropdowns
- OpenRouter model routing
- optional custom model IDs
- live run output
- improve / continue controls
- scoring and transcript logging

### AI Bug Report Builder

A helper workspace for organizing AI security findings into a clearer report-style structure.

Useful for:

- model behavior notes
- AI app bug report drafts
- evidence organization
- reproduction outline drafting
- severity and triage notes
- evaluator model review
- copy-ready report output

### AI Chat

A direct chat workspace.

Includes:

- model selector
- OpenRouter key input
- system message editor
- streaming chat
- compact model/status/credits chips
- prompt suggestion buttons
- local transcript logging

### Transcripts

Lists saved local JSONL transcripts.

Logs are written under:

```text
logs/
```

By default, logs should not be committed to GitHub.

### Rules

A short reminder page for authorization, provider terms, and scope.

---

## Project structure

```text
.
├── app.py
├── requirements.txt
├── README.md
├── templates/
│   └── index.html
├── static/
│   └── assets/
│       ├── canary-logo-v2.png
│       ├── canary-pixel-symbol-transparent.png
│       ├── canary-pixel-symbol.png
│       └── canary-red-logo.png
└── logs/
```

Important files:

- `app.py` - Flask backend, API routes, OpenRouter calls, logging
- `templates/index.html` - full CANARY frontend UI
- `requirements.txt` - Python dependencies
- `static/assets/` - CANARY logo assets
- `logs/` - local chat/report transcript output

---

## API key handling

CANARY is a local app. API keys are entered in the browser and sent to your local Flask server.

Recommended:

- Do not commit keys to GitHub.
- Do not hardcode keys into `app.py`.
- Do not paste real secrets into screenshots.
- Keep `.venv/`, `logs/`, and local environment files out of Git.

---

## Troubleshooting

CANARY VERSION 1 is still early software. Most issues will come from local Python setup, API key/authentication problems, unavailable model endpoints, or a stale browser cache.

### `ModuleNotFoundError: No module named 'flask'`

Install dependencies:

```powershell
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

### Site cannot be reached

Start the server:

```powershell
.\.venv\Scripts\python.exe app.py
```

Then open:

```text
http://127.0.0.1:5000
```

### Port 5000 is already in use on Windows

Find the process:

```powershell
netstat -ano | Select-String ':5000'
```

Stop the listed PID:

```powershell
Stop-Process -Id <PID> -Force
```

Then restart:

```powershell
.\.venv\Scripts\python.exe app.py
```

### Model endpoint unavailable

OpenRouter model availability changes. If a model fails with a missing endpoint:

1. Pick another model from the dropdown.
2. Check OpenRouter model availability.
3. Use a custom OpenRouter model ID if needed.

Common endpoint errors include:

```text
No endpoints found for <model>
```

or:

```text
Error code: 404
```

These usually mean the selected OpenRouter model is temporarily unavailable, renamed, or not available for your account/key.

### Authentication errors

If you see:

```text
401
Authentication Failed
Missing Authentication header
invalid x-api-key
```

check that:

- your OpenRouter key is pasted correctly
- there are no extra spaces before or after the key
- the key has not expired or been revoked
- your account has access to the selected model

### Early VERSION 1 limitations

Known rough edges:

- Model availability can change without warning.
- Some models stream slower than others.
- Some providers may return different error formats.
- The UI may need a hard refresh after updates.
- Logs are local JSONL files and not a full database.
- Credit counting is approximate when providers do not return exact usage.
- This is a local development server, not a production deployment.

### UI does not update after changes

Hard refresh:

```text
Ctrl + F5
```

---

## GitHub publishing checklist

Before publishing:

- Remove any private logs you do not want public.
- Check `logs/` is ignored.
- Check `.venv/` is ignored.
- Check no API keys are committed.
- Check screenshots do not show keys.
- Add a repository description.
- Add a license if you want others to reuse the code.
- Create a clean first commit.

Example:

```bash
git init
git add app.py templates static requirements.txt README.md .gitignore
git commit -m "Initial CANARY VERSION 1 release"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

---

## Responsible use

CANARY is for authorized AI testing, development, and research. You are responsible for how you use models, prompts, logs, transcripts, and API keys.

Follow:

- applicable laws
- provider terms
- program scopes
- written authorization requirements
- responsible disclosure expectations

Do not use CANARY against systems, data, or services you do not own or have explicit permission to test.

---

## Version

```text
CANARY VERSION 1
```
