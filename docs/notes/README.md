# Project notes

Working notes, decisions and standing orders for this project, kept by Claude Code while working with rhY. Each file is one fact or decision; `[[name]]` links point to other notes (some live in other crhy repos' `docs/notes/`).

- [delegate-coding-to-local-qwen](delegate-coding-to-local-qwen.md): rhY wants coding tasks handed to the local Qwen model (Strata + OpenCode) one at a time to save Claude tokens; Claude writes prompts, reviews and gates.
- [long-agent-runs-watch-for-stalls](long-agent-runs-watch-for-stalls.md): When running slow background agent jobs (local-AI opencode batches), detect stalls and failures early and relaunch fast instead of letting them burn time.
- [watch-strata-speed](watch-strata-speed.md): While Qwen/Strata tasks run, rhY expects Claude to watch tokens/sec and system memory, not just task completion
- [tmp-is-ram-on-this-machine](tmp-is-ram-on-this-machine.md): /tmp is tmpfs (RAM) on rhY's workstation; never leave large files or per-run temp dirs there
- [brave-stays-open](brave-stays-open.md): rhY keeps Brave open while Strata runs and won't close it; never suggest closing it
- [no-desktop-automation](no-desktop-automation.md): Never drive rhY's desktop with xdotool/scrot automation — but the headless macOS VM is explicitly fair game to automate.
- [strata-ram-budget](strata-ram-budget.md): (superseded 2026-11-10 by strata-96gb-upgrade) Strata holds ~20.8 GB of non-reclaimable RAM; with Brave open only ~2.4 GB headroom is left; running out freezes rhY's PC (2026-10-30)
- [strata-self-tuning-plan](strata-self-tuning-plan.md): Planned (not yet started): Strata tunes its own server flags via an outside harness; run only AFTER the first SuperMox beta release AND the Spaced app theming fixes
- [strata-pi-launcher](strata-pi-launcher.md): rhY's "Strata (pi)" Brisk-menu favourite (~/.local/bin/strata-pi) for working with Strata directly when Claude tokens run out
- [strata-pi-compaction-fix](strata-pi-compaction-fix.md): pi "Summarization failed: token cap" / truncated write on Strata was snowballing compaction summaries; fixed by ~/.pi/agent/extensions/strata-compaction.ts (2026-11-01).
- [strata-vs-avalon-ab](strata-vs-avalon-ab.md): Strata vs Avalon A/B = both engines build Spaced Monitor from the same 9 tasks; setup, files and how to resume (2026-10-31)
- [notes-live-on-github](notes-live-on-github.md): rhY's rule (2026-11-01): all Spaced/theme data and every memory note must be on GitHub; upload each note to its repo's docs/notes/ right after writing it.
- [strata-96gb-upgrade](strata-96gb-upgrade.md): 2026-11-10 RAM 32->96 GB: what broke Strata (pi), discoveries, the IQ3_S full-model install, harness changes, BIOS (RAM at 3600 MT/s) and DeepSeek verdicts.
- [strata-context-lesson](strata-context-lesson.md): The Coder sat at 64K context for weeks after RAM allowed more; 128K/256K made it clearly better at once. Re-derive limits whenever hardware changes.
- [always-open-pi-window](always-open-pi-window.md): Starting Strata always opens the pi window too, so rhY can watch; never --server-only.
