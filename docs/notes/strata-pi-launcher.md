---
name: strata-pi-launcher
description: rhY's "Strata (pi)" Brisk-menu favourite (~/.local/bin/strata-pi) for working with Strata directly when Claude tokens run out
metadata:
  type: reference
---

`~/.local/bin/strata-pi` (desktop entry `strata-pi.desktop`, icon `strata-pi`, first Brisk favourite since 2026-10-31):
if Strata is not loaded it runs `strata-opencode-starter --model coder-iq1_m` (project dialog, server, btop, nvtop, the
queue's pi window with strata-inbox); if Strata is already running it leaves the server alone and opens a PLAIN pi window
in a chosen folder (no DISPLAY, `-e ~/.local/share/strata-opencode-starter/strata-guard.ts` = 20-min default bash
timeout), so the task queue keeps running and requests just wait their turn. Related: [[delegate-coding-to-local-qwen]].
