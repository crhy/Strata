---
name: watch-strata-speed
description: While Qwen/Strata tasks run, rhY expects Claude to watch tokens/sec and system memory, not just task completion
metadata:
  type: feedback
---

rhY expects me to keep an eye on the Strata instance itself while it works: tokens per second, memory, swap and disk reads — not only whether a task finished.

**Why:** On 2026-10-05 rhY had to ask "why is qwen getting < 10 tokens/sec?" and then said "You're supposed to be keeping an eye on strata!" after it had run at 5–9 tok/s (normal for the Coder model is roughly 77–84 writing) for over an hour because of memory pressure I had caused. The original mandate was "monitor the strata instance I'm running".

**How to apply:** Every time I check on a Qwen task, also read the last tok/s lines in `~/.local/state/strata-opencode-starter/strata-server.log` and glance at `free`/`vmstat`. If writing speed is far below normal, investigate at once (memory, swap, heavy disk reads, GPU sharing with Ollama/Whisper/the face server) and tell rhY without being asked. Related: [[tmp-is-ram-on-this-machine]], [[long-agent-runs-watch-for-stalls]], [[delegate-coding-to-local-qwen]].

**Repeated 2026-10-23:** I ran `mksquashfs` (4 threads, it buffers up to ~25% of RAM) plus a 6.8 GB file move while Strata worked; RAM fell to 266 MB with swap exhausted, speed dropped to 6.8 tok/s and the Strata server restarted mid-task. Don't run heavy CPU/RAM/disk jobs (squashfs, ISO builds, big copies, compression benchmarks) while a Strata queue is active — run them between queues, or pause them (`kill -STOP`) while Strata generates.
