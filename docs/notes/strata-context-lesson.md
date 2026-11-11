---
name: strata-context-lesson
description: The Coder was held at 64K context for weeks after RAM allowed more; 128K/256K made it clearly better at once. Re-check limits whenever hardware or models change.
metadata:
  type: feedback
---
Raising the Coder from 64K to 128K context (2026-11-10) made Strata noticeably better at once: far fewer pi
compactions, so it keeps the real code and errors in view instead of lossy summaries; speed didn't drop (63-80 tok/s).
rhY: "We should have upped the context for the coder WEEKS ago." Strata's own docs said the Coder runs 262K on 64 GB.

**Why:** compaction losses were the main quality ceiling, not the model; the 64K cap was a stale 32 GB-era choice.
**How to apply:** whenever hardware, model or engine changes, re-derive context, compaction (reserve/keepRecent),
reasoning budget, maxTokens and task-header reading limits from the docs and measured RAM; don't carry old caps over.
Related: [[strata-96gb-upgrade]], [[strata-pi-compaction-fix]].
