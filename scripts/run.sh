#!/usr/bin/env bash
# Starts pi in an Apple container.
#
# Expects mounts:
#   - pi-config/{settings.json,models.json,AGENTS.md,extensions/,bin/,sessions/}
#       -> /home/pi/.pi/agent/...          (provider config, extensions, sessions)
#   - $PROJECT_DIR  -> /workspace          (the project to work on)
#   The image's pre-installed npm/ (linux/arm64 native modules) is NOT shadowed.
#
# Example:
#   PROJECT_DIR=~/projects/small-test-repo ./scripts/run.sh --model mlx-local/qwen3-coder
set -euo pipefail

IMAGE_TAG="${IMAGE_TAG:-pi-coding-agent:local}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "PROJECT_DIR='$PROJECT_DIR' does not exist." >&2
  exit 1
fi

cat <<'BANNER'
_\__o__ __o/   o__ __o
     v    |/  <|     v\
         /    / \     <\
       o/     \o/     o/    o__ __o     o      o
      /v       |__  _<|    /v     v\   <|>    <|>
     />        |       \  />       <\  < >    < >
   o/         <o>      /  \         /   \o    o/
  /v           |      o    o       o     v\  /v
 />  _\o__/_  / \  __/>    <\__ __/>      <\/>
                                           /
                                          o
                                       __/>
BANNER
echo ""
echo "A sovereign, local coding agent on macOS."
echo "→ https://github.com/abhayparolkar/ZBoy"
echo ""

container run \
  --rm \
  --interactive \
  --tty \
  --cpus 2 \
  --memory 4G \
  --volume "$REPO_ROOT/pi-config/settings.json:/home/pi/.pi/agent/settings.json" \
  --volume "$REPO_ROOT/pi-config/models.json:/home/pi/.pi/agent/models.json" \
  --volume "$REPO_ROOT/pi-config/AGENTS.md:/home/pi/.pi/agent/AGENTS.md" \
  --volume "$REPO_ROOT/pi-config/extensions:/home/pi/.pi/agent/extensions" \
  --volume "$REPO_ROOT/pi-config/bin:/home/pi/.pi/agent/bin" \
  --volume "$REPO_ROOT/pi-config/sessions:/home/pi/.pi/agent/sessions" \
  --volume "$PROJECT_DIR:/workspace" \
  --workdir /workspace \
  "$IMAGE_TAG" \
  "$@"
