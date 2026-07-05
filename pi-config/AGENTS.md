# Global Agent Rules (Container Variant)

## Runtime Context
- This session runs inside an Apple container. The host Mac is not directly accessible; file operations are confined to `/workspace`.


## Language & Tone
- Respond in English, unless the prompt explicitly requests other language.
- Technically precise, no marketing speak.

## Tool Discipline
- Before making larger changes: read relevant files using `read`, then edit.
- Use `bash` for utilities (`ls`, `grep`, `find`, `rg`) — not for logic.
- Use `write` only for new files; use `edit` for modifications.
- No `npm install`/`pip install` calls without explicit confirmation.
- Do not write to paths outside `/workspace`.

## Sovereignty & Data Integrity
- No external API calls (`curl`, `fetch`, webhooks) without explicit instruction.
- No telemetry or analytics snippets in generated code.
- If the scope is unclear: ask first, do not assume.

## Session Hygiene
- When nearing the context limit: suggest summarization instead of endless compression.
- Errors are read (acknowledged), not bypassed.
