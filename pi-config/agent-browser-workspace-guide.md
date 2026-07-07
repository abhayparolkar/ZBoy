# Agent-Browser Workspace Screenshot & Recording Guide

## Overview

Use agent-browser to capture screenshots and recordings, with automatic directory creation under `/workspace/workfeed/`.

## Screenshot Workflow

### Basic Usage

```bash
# Capture a screenshot and save it
agent-browser screenshot /workspace/workfeed/screenshot_<timestamp>.png
```

### Full Workflow Example

```bash
# Open the page
agent-browser open https://example.com

# Take a screenshot (timestamp auto-generated)
agent-browser screenshot /workspace/workfeed/screenshot_20260707123456.png

# Interact with the page
agent-browser click @e4
agent-browser wait 500

# Take another screenshot after interaction
agent-browser screenshot /workspace/workfeed/screenshot_20260707123457.png
```

### Built-in Options

| Option | Description |
|--------|-------------|
| `--full` | Capture the entire page including below-fold content |
| `--annotate` | Add numbered labels with a legend (useful for debugging) |
| `@selector` | Capture a specific DOM element before saving |

### Examples with Options

```bash
# Full-page capture
agent-browser screenshot --full /workspace/workfeed/screenshot_full.png

# Annotated capture (labels overlap real content on dense pages)
agent-browser screenshot --annotate /workspace/workfeed/screenshot_annotated.png

# Specific element capture
agent-browser screenshot @e4 /workspace/workfeed/screenshot_elem.png
```

## Recording Workflow

### Basic Usage

```bash
# Start recording a video
agent-browser record start ./workspace/workfeed/checkout.webm

# Wait for the action
agent-browser wait 5000

# Interact with the page
agent-browser click @e4
agent-browser wait 5000

# Stop recording
agent-browser record stop
```

### Complete Recording Example

```bash
# Open the site
agent-browser open https://shop.example.com

# Start recording
agent-browser record start ./workspace/workfeed/checkout.webm

# Wait a moment for initial load
agent-browser wait 2000

# Navigate through the checkout
agent-browser click @e2
agent-browser wait 1000
agent-browser click @e5
agent-browser wait 1000
agent-browser click @e8

# Stop recording
agent-browser record stop
```

## Directory Creation

**Automatic:** If `/workspace/workfeed/` doesn't exist, agent-browser will create it before saving files.

**Manual override:** You can specify a custom directory:

```bash
agent-browser screenshot /workspace/my-project/screenshots/test.png
agent-browser record start ./workspace/my-project/recordings/video.webm
```

## Best Practices

1. **Use descriptive filenames**: Include test names, timestamps, or feature identifiers
2. **Batch screenshots**: Take multiple screenshots at key interaction points
3. **Document your workflow**: Comment your bash scripts with what each screenshot captures
4. **Keep recordings short**: Stop recordings as soon as needed to save bandwidth
5. **Verify saves**: Check that screenshots exist and have non-zero size

## Troubleshooting

### Screenshot not created?
- Verify you're pointing to an absolute path starting with `/workspace`
- Check if the directory exists or has write permissions
- Ensure agent-browser completed without errors (check for timeout/partial progress)

### Empty/zero-byte screenshots?
- The page may have not loaded fully—add `agent-browser wait 1000` before screenshot
- Try `--full` flag if content is below the fold

### Recording stuck?
- Check for JavaScript errors in the browser console
- Ensure ffmpeg is available on the PATH if needed for recording
- Restart with `agent-browser record start --force`

## Artifacts Verification

After saving, verify your file:

```bash
# Check file exists
ls -la /workspace/workfeed/screenshot_*.png

# Check file size (should be > 0)
stat /workspace/workfeed/screenshot_*.png

# For recordings, check duration
ffprobe /workspace/workfeed/video.webm 2>/dev/null || echo "Need ffmpeg"
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `AGENT_BROWSER_SCREENSHOT_DIR` | `/workspace/workfeed/` | Default screenshot output directory |
| `AGENT_BROWSER_SCREENSHOT_QUALITY` | `80` | JPEG quality (0-100) |
| `AGENT_BROWSER_SCREENSHOT_FORMAT` | `png` | Output format: `png` or `jpeg` |
| `AGENT_BROWSER_ANNOTATE` | `false` | Enable annotated screenshots |

Example:

```bash
export AGENT_BROWSER_SCREENSHOT_DIR="/workspace/artifacts/screenshots"
agent-browser screenshot /workspace/artifacts/screenshots/test.png
```

## Combined Session Example

```bash
#!/bin/bash

# Open and document
agent-browser open https://abhishek.parolkar.com
agent-browser screenshot /workspace/workfeed/screenshot_page_1.png
agent-browser wait 1000

# Interact
agent-browser click @e5
agent-browser screenshot /workspace/workfeed/screenshot_page_2.png
agent-browser wait 1000

# Close
agent-browser close
```
