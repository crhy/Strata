---
name: always-open-pi-window
description: Whenever Claude starts Strata, the pi window must open too (never --server-only), so rhY can watch.
metadata:
  type: feedback
---
Starting Strata means server + the pi window (strata-inbox), never `--server-only`, even for a smoke test.

**Why:** rhY, 2026-11-10: "you ARE supposed to start the Pi terminal so I can watch what it's doing" after Claude used --server-only.
**How to apply:** use the starter's normal launch; if the server is already up, open the pi window with the saved
run/pi___<project>___Strata.sh script (clear pi-inbox current/pi.pid/*.running/*.abort first). Related: [[strata-96gb-upgrade]].
