---
name: long-agent-runs-watch-for-stalls
description: When running slow background agent jobs (local-AI opencode batches), detect stalls and failures early and relaunch fast instead of letting them burn time.
metadata:
    pinned: false
---

rhY's local Qwen model generates only about 18 tokens per second, so a batch of
work through opencode takes tens of minutes to an hour, and rhY is waiting on it.
After a headless opencode run silently ended without writing anything (it hit an
auto-rejected permission request and I only noticed when it finished, roughly half
an hour in), rhY said: "Just don't let it waste half an hour like earlier."

So for any long background job: set up failure and stall detection from the start
(run ended with no changes, rejected permission, server not answering, model idle
with no activity), check on it proactively and honestly, and fix the cause and
relaunch straight away rather than waiting for it to finish. Give the job what it
needs to move fast: exact task lists, verified API snippets, and an instruction to
write files first rather than exploring. Keep status updates plain and specific.
