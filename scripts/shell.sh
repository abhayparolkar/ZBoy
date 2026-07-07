#!/usr/bin/env bash
# Opens an interactive Linux shell in the pi-container image with the same
# mounts and resource limits as run.sh, but without launching the pi agent.
#
# Usage is identical to run.sh — set PROJECT_DIR to point at your project:
#
#   PROJECT_DIR=~/projects/your-repo ./scripts/shell.sh
#
set -euo pipefail

IMAGE_TAG="${IMAGE_TAG:-pi-coding-agent:local}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "PROJECT_DIR='$PROJECT_DIR' does not exist." >&2
  exit 1
fi

container run \
  --rm \
  --interactive \
  --tty \
  --cpus 2 \
  --memory 4G \
  --shm-size 1g \
  --entrypoint bash \
  --volume "$REPO_ROOT/pi-config/settings.json:/home/pi/.pi/agent/settings.json" \
  --volume "$REPO_ROOT/pi-config/models.json:/home/pi/.pi/agent/models.json" \
  --volume "$REPO_ROOT/pi-config/AGENTS.md:/home/pi/.pi/agent/AGENTS.md" \
  --volume "$REPO_ROOT/pi-config/extensions:/home/pi/.pi/agent/extensions" \
  --volume "$REPO_ROOT/pi-config/bin:/home/pi/.pi/agent/bin" \
  --volume "$REPO_ROOT/pi-config/sessions:/home/pi/.pi/agent/sessions" \
  --volume "$PROJECT_DIR:/workspace" \
  --workdir /workspace \
  "$IMAGE_TAG"
