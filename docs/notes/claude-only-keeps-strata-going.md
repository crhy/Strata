---
name: claude-only-keeps-strata-going
description: rhY 2026-11-11 - Claude's only job is to keep Strata's queue running and spend as few Claude tokens as possible.
metadata:
  type: feedback
---
Claude queues tasks for Strata, keeps the queue >=3 deep, checks briefly, and replies tersely. No long reviews, research or
explanations unless asked; let Strata do the investigation, code and docs.

**Why:** rhY said "Your only job is to keep strata going and save Claude tokens."
**How to apply:** short replies, few tool calls, delegate everything else. Related: [[delegate-coding-to-local-qwen]], [[keep-strata-queue-deep]].
