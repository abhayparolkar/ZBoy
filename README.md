<p align="center">
  <img src="blog-image.jpg" alt="pi coding agent in an Apple Container" width="100%">
</p>

<h1 align="center">ZBoy - A sovereign, local coding agent on macOS.</h1>

<p align="center">
  <strong>A sovereign AI agent capable of running on 16G mac. It is fun! </strong><br>
  The <code>pi</code> coding agent runs in a disposable Apple <code>container</code> micro-VM and talks to a local
  MLX model on the host via <strong>oMLX</strong> — no Node, no npm, no agent binary on your work machine.
  Built for <strong>Rails 8</strong> applications with integrated browser & messaging support, but capable of building
  and maintaining <strong>anything</strong>.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2026%20(Tahoe)%20%C2%B7%20Apple%20Silicon-black" alt="platform">
  <img src="https://img.shields.io/badge/runtime-Apple%20container-blue" alt="runtime">
  <img src="https://img.shields.io/badge/agent-pi--coding--agent%20%C2%B7%20Node%2022-339933" alt="agent">
  <img src="https://img.shields.io/badge/model-MLX--Qwen3.5--9B--GLM5.1--Distill--v1--6bit-orange" alt="model">
  <img src="https://img.shields.io/badge/inference-oMLX-9cf" alt="inference">
  <img src="https://img.shields.io/badge/status-hands--on%20draft-yellow" alt="status">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="license">
</p>

---

## Overview

A modern coding agent reads your files, runs shell commands, and installs whatever it decides it needs. On a work machine in a regulated context that is an unacceptable blast radius. This repository contains a **runnable setup** that closes it:

- **Inference stays native on the host** — MLX needs Apple Silicon's Metal/ANE, which a Linux VM does not expose. The default model is **MLX-Qwen3.5-9B-GLM5.1-Distill-v1-6bit**, served locally via **oMLX**.
- **The agent runtime is sandboxed in its own VM** — Apple `container` gives each container a lightweight VM, not shared-kernel namespaces.
- **The host stays clean** — no Node, no npm, no `pi` binary; the agent lives only inside an image and is discarded on exit.

The full step-by-step walkthrough is the article **[`en-pi-apple-container.md`](en-pi-apple-container.md)**.

## Architecture

```
┌─────────────────────────────┐        ┌──────────────────────────────┐
│ Host (macOS, Apple Silicon) │        │ Apple Container (Linux VM)   │
│                             │        │                              │
│  oMLX server                │◄──────►│  pi-coding-agent             │
│  /v1/chat/completions       │ Bridge │  (Node 22, ripgrep, git,     │
│  MLX-Qwen3.5-9B-GLM5.1-     │        │   Ruby, Rails, ffmpeg,       │
│    Distill-v1-6bit          │        │   SQLite)                    │
└─────────────────────────────┘        │  Workspace: /workspace       │
                                      └──────────────────────────────┘
```

- **Inference** runs on the host via oMLX (no Metal/ANE in a Linux VM).
- **Tool-calling sandbox** runs in the container — a clean split between model runtime and agent runtime.
- **pi** reaches the host only over the container bridge; the gateway IP is discovered at runtime.

## Repository structure

```
.
├── Containerfile                   # node:22-bookworm-slim + pi, Ruby, Rails, ffmpeg, SQLite
├── pi-config/
│   ├── AGENTS.md                   # global agent rules (container variant)
│   ├── models.json                 # provider + model definition (oMLX)
│   ├── settings.json               # pi runtime settings + package list
│   ├── npm/                        # extension packages (npm-installed)
│   └── extensions/
│       └── protected-paths/
│           └── index.ts            # tool-call guardrail for sensitive paths
└── scripts/
    ├── build.sh                    # container build
    ├── run.sh                      # container run with the right mounts
    └── shell.sh                    # interactive shell in the same container environment
```

`pi-config/` is mounted into the container at runtime as the agent's config directory.

## Prerequisites

- **macOS 26 (Tahoe) on Apple Silicon** (recommended). Container-to-host networking is the linchpin; older macOS limits it severely.
- Apple `container` CLI (`container --version` must answer).
- **oMLX** running on the host, serving an OpenAI-compatible `/v1/chat/completions` endpoint bound to `0.0.0.0` (not `127.0.0.1`). The default model is `MLX-Qwen3.5-9B-GLM5.1-Distill-v1-6bit`.
- **No Node and no npm on the host** — that is the point; the agent lives only in the image.

## Quickstart

### 1. Build

```bash
./scripts/build.sh
```

### 2. Find the bridge IP

```bash
container run --rm --entrypoint sh pi-coding-agent:local \
  -c "ip route | awk '/default/ {print \$3}'"
```

Update `baseUrl` in `pi-config/models.json` if the printed IP differs (keep the `:8888/v1` suffix).

### 3. Run

```bash
PROJECT_DIR=~/projects/your-repo ./scripts/run.sh
```

That's it. `run.sh` mounts `pi-config/` → agent config and `$PROJECT_DIR` → `/workspace`. The VM is discarded on exit.

### 4. Shell (optional)

To open an interactive Linux shell in the same container environment (same mounts, resource limits, and `pi` user) without starting the agent:

```bash
PROJECT_DIR=~/projects/your-repo ./scripts/shell.sh
```

Useful for debugging, inspecting the filesystem, or running commands manually inside the container.

## Configuration

### Models — `pi-config/models.json`

Defines the `mlx-local` provider pointing at the oMLX server. `apiKey` is `"not-required"` (local server, no secret to leak). The model `id` must match exactly what oMLX reports — currently **`MLX-Qwen3.5-9B-GLM5.1-Distill-v1-6bit`**.

### Global agent rules — `pi-config/AGENTS.md`

Loaded into every session: runs in a container, host not directly reachable, file ops only in `/workspace`, no external calls without explicit instruction, and tool discipline (`read` before `edit`, `write` only for new files).

### Extension — `protected-paths`

Hooks pi's `tool_call` event and forces confirmation (or hard-denies) for sensitive paths (`~/.ssh`, `~/.aws`, `.env`, `credentials.json`, `*.pem`, etc.). Defense-in-depth for the day someone widens a mount.

### Messenger bridge — `pi-messenger-bridge`

Bridges common messengers (Telegram, WhatsApp, Slack, Discord, Matrix) into pi so remote users can interact with the agent from their phone or chat app.

**Installed as an npm extension** — listed in `pi-config/settings.json` under `packages` and installed in `pi-config/npm/`. No changes to the Containerfile are needed; the package is picked up at runtime from the mounted config volume.

#### Supported transports

| Transport | Setup |
|---|---|
| **Telegram** | Create a bot via [@BotFather](https://t.me/BotFather), set `PI_TELEGRAM_TOKEN` |
| **WhatsApp** | Run `/msg-bridge configure whatsapp`, scan QR code |
| **Slack** | Create a Socket Mode app, set `PI_SLACK_BOT_TOKEN` + `PI_SLACK_APP_TOKEN` |
| **Discord** | Create a bot in the [Developer Portal](https://discord.com/developers/applications), enable Message Content Intent, set `PI_DISCORD_TOKEN` |
| **Matrix** | Register a bot account, set `PI_MATRIX_HOMESERVER` + `PI_MATRIX_ACCESS_TOKEN` |

#### Usage

```bash
# Interactive setup menu (inside a pi session)
/msg-bridge

# Configure a specific transport
/msg-bridge configure telegram

# Connect to all configured transports
/msg-bridge connect

# Check status
/msg-bridge status
```

Credentials can be set via environment variables (prefixed `PI_*`) or stored in `~/.pi/msg-bridge.json`. Environment variables take precedence. New users authenticate via a 6-digit challenge code displayed in the pi terminal.

See the [pi-messenger-bridge README](https://github.com/tintinweb/pi-messenger-bridge) for full documentation.

## Troubleshooting

| Symptom | Cause & fix |
|---|---|
| Requests hang, no error | **Local Network permission not granted.** *System Settings → Privacy & Security → Local Network* — enable the container runtime, then reopen. |
| "Can't reach the model" | **oMLX bound to loopback.** Bind to `0.0.0.0`. |
| Connection refused | **Wrong bridge IP.** Re-run step 2 and update `models.json`. |
| Files owned by UID 1000 | **Expected.** Container writes as `pi` (UID 1000). Acceptable in the pi edit-workflow. |
| Agent answers but never edits | **No native tool-calling.** Verify the model supports OpenAI function-calling. |

## Notes & caveats

- **MLX stays on the host.** No Metal/ANE inside a Linux VM.
- **Bridge IP is environment-dependent** — discovered at runtime, never hardcoded.
- **API keys are never committed.** `models.json` uses `"not-required"` for local oMLX servers.

## License

Licensed under the MIT License — see [`LICENSE`](LICENSE).
