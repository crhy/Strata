---
name: strata-pi-compaction-fix
description: pi "Summarization failed: token cap" / truncated write on Strata was snowballing compaction summaries; fixed by ~/.pi/agent/extensions/strata-compaction.ts (2026-11-01).
metadata:
  type: project
---
Root cause (StrataMixing session 2026-11-01): pi's default compaction rewrites previous summary + new history each time, so the summary grew 4.7K→47K chars over 10 compactions. Once it needed >16384 output tokens every compaction failed (3 min each), context ran to the 64K window and the next big `write` was truncated ("Context overflow recovery failed").

Fix: `~/.pi/agent/extensions/strata-compaction.ts` (auto-loaded by pi window and headless pi) handles `session_before_compact` for provider `strata`: 700-word budget, thinking off via `chat_template_kwargs.enable_thinking=false` (thinkingFormat qwen-chat-template; Strata server honours it), clips history/previous summary/file lists, and falls back to a mechanical summary instead of failing. Tested on a copy of the broken session: 1.1K tokens, 5K chars, ~46 s.

**Why:** rhY: "This has gone on long enough" — don't go back to tuning reserveTokens/maxTokens (four .bak attempts already in ~/.pi/agent).
**How to apply:** if the error returns, check compaction entries' summary length/usage in the session jsonl first; a running pi window needs `/reload` to pick up extension changes. Related: [[delegate-coding-to-local-qwen]], [[long-agent-runs-watch-for-stalls]].
