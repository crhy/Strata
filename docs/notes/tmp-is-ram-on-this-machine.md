---
name: tmp-is-ram-on-this-machine
description: /tmp is tmpfs (RAM) on rhY's workstation; never leave large files or per-run temp dirs there
metadata:
  type: feedback
---

On rhY's Spaced Linux workstation `/tmp` is a tmpfs, so anything written there uses RAM and then swap.

**Why:** On 2026-10-05 my Voxa real-app check scripts left 36 temp folders in `/tmp`, each holding a 220 MB Whisper download (8.8 GB total). That filled swap and pushed Strata's model out of the page cache, dropping Qwen from ~80 to 5–9 tokens/sec for over an hour until rhY noticed and asked. Deleting them brought it back.

**How to apply:** Put scratch data on disk (the session scratchpad or the project's ignored out/ folder), remove per-run temp dirs at exit, and keep download caches persistent instead of re-downloading. Before and during long local-model runs, check `findmnt /tmp` usage, `free`, and swap. See [[long-agent-runs-watch-for-stalls]].
