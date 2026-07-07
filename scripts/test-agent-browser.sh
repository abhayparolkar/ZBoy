#!/usr/bin/env bash
# test-agent-browser.sh — Validates agent-browser works inside the Pi container
# using Playwright's Chromium (not system Chromium which SIGTRAPs on aarch64).
#
# Run this INSIDE the container:
#   scripts/test-agent-browser.sh
#
# Or from the host via shell.sh:
#   PROJECT_DIR=. ./scripts/shell.sh -c "/workspace/scripts/test-agent-browser.sh"
set -uo pipefail

TARGET_URL="${TARGET_URL:-https://abhay.parolkar.com}"
SCREENSHOT_DIR="${SCREENSHOT_DIR:-/tmp}"
PASS=0
FAIL=0

ok()   { echo "  ✓ PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ FAIL: $1"; FAIL=$((FAIL + 1)); }

echo ""
echo "============================================"
echo "  agent-browser validation suite"
echo "  Target: $TARGET_URL"
echo "============================================"
echo ""

# ---------------------------------------------------------------------------
# PRE-STEP: Bootstrap D-Bus (in case entrypoint was bypassed via shell.sh)
# ---------------------------------------------------------------------------
echo "=== PRE-STEP: Bootstrap D-Bus ==="
if [ ! -S /run/dbus/system_bus_socket ]; then
  mkdir -p /run/dbus
  dbus-daemon --system --fork 2>/dev/null || true
  sleep 1
fi
[ -S /run/dbus/system_bus_socket ] && ok "system bus socket" || fail "system bus socket"

if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
  export DBUS_SESSION_BUS_ADDRESS=$(dbus-daemon --session --fork --print-address=1 2>/dev/null || true)
fi
[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] && ok "session bus ($DBUS_SESSION_BUS_ADDRESS)" || fail "session bus"
echo ""

# ---------------------------------------------------------------------------
# TEST 0: Environment preconditions
# ---------------------------------------------------------------------------
echo "=== TEST 0: Environment ==="
command -v chromium-wrapper >/dev/null 2>&1 && ok "chromium-wrapper on PATH" || fail "chromium-wrapper NOT on PATH"
command -v chromium-playwright >/dev/null 2>&1 && ok "chromium-playwright on PATH" || fail "chromium-playwright NOT on PATH"

CHROME_VER=$(chromium-playwright --version 2>&1 || echo "unknown")
echo "  Chromium: $CHROME_VER"

[ -n "${AGENT_BROWSER_EXECUTABLE_PATH:-}" ] && ok "AGENT_BROWSER_EXECUTABLE_PATH=$AGENT_BROWSER_EXECUTABLE_PATH" || fail "AGENT_BROWSER_EXECUTABLE_PATH not set"
echo ""

# ---------------------------------------------------------------------------
# TEST 1: Direct chromium-playwright launch
# ---------------------------------------------------------------------------
echo "=== TEST 1: Direct Chromium launch ==="
TMPDIR=$(mktemp -d)
chromium-wrapper --user-data-dir="$TMPDIR/profile" --remote-debugging-port=0 > "$TMPDIR/chrome.log" 2>&1 &
PID=$!
CDP_READY=false
for i in $(seq 1 16); do
  [ -f "$TMPDIR/profile/DevToolsActivePort" ] && { CDP_READY=true; break; }
  sleep 0.5
done
kill "$PID" 2>/dev/null || true; wait "$PID" 2>/dev/null || true
if [ "$CDP_READY" = "true" ]; then
  ok "Chromium launched and wrote DevToolsActivePort"
else
  fail "Chromium did not write DevToolsActivePort"
  tail -5 "$TMPDIR/chrome.log" | sed 's/^/    /'
fi
rm -rf "$TMPDIR"
echo ""

# ---------------------------------------------------------------------------
# TEST 2: agent-browser doctor
# ---------------------------------------------------------------------------
echo "=== TEST 2: agent-browser doctor ==="
agent-browser doctor 2>&1 && ok "doctor passed" || fail "doctor failed"
echo ""

# ---------------------------------------------------------------------------
# TEST 3: Open target URL
# ---------------------------------------------------------------------------
echo "=== TEST 3: Open $TARGET_URL ==="
agent-browser open "$TARGET_URL" 2>&1 && { ok "open succeeded"; sleep 2; } || fail "open failed"
echo ""

# ---------------------------------------------------------------------------
# TEST 4: Take screenshot
# ---------------------------------------------------------------------------
echo "=== TEST 4: Screenshot ==="
SHOT="$SCREENSHOT_DIR/agent-browser-test-$(date +%s).png"
agent-browser screenshot "$SHOT" 2>&1
if [ -f "$SHOT" ] && [ "$(stat -c%s "$SHOT" 2>/dev/null || stat -f%z "$SHOT" 2>/dev/null || echo 0)" -gt 100 ]; then
  ok "screenshot saved ($SHOT, $(stat -c%s "$SHOT" 2>/dev/null || stat -f%z "$SHOT" 2>/dev/null) bytes)"
else
  fail "screenshot failed"
fi
echo ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo "============================================"
echo "  RESULTS: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "  ALL TESTS PASSED ✅" || echo "  SOME TESTS FAILED ❌"
echo "============================================"
echo ""
exit "$FAIL"
