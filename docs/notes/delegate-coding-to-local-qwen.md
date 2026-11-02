---
name: delegate-coding-to-local-qwen
description: rhY wants coding tasks handed to the local Qwen model (Strata + OpenCode) one at a time to save Claude tokens; Claude writes prompts, reviews and gates.
metadata:
  type: feedback
---

On 2026-10-03, during Voxa work, after I rewrote the preferences dialog myself, rhY said:
"Make sure you're assigning qwen most of those tasks one at a time to save tokens."

**Why:** rhY has a capable local model (Qwen3.8 Flash Next on Strata, driven through
OpenCode) and wants Claude's token use kept down.

**How to apply:** when the local model is running, give it implementation work as one
small, exact, file-level prompt at a time (see [[long-agent-runs-watch-for-stalls]] for
how to keep those runs from stalling), and limit my own part to writing the prompt,
early stall checks, reviewing the diff and running the gate. The runner that does this
for Voxa is `/Voxa/.voxa-spec/tasks/agent/run-step.sh`. Doing a change by hand is still
fine for a few-line fix where a prompt would cost more than the edit. Scope: stated for
Voxa; my interpretation is that it applies to rhY's other projects whenever the local
model is up.

**Repeated 2026-10-10 about 16:05** during the issue-102 loop: "Try to use more strata and less opus. Keep going." I had been hand-polishing the local model's output and hand-writing spoken test cases. How to apply now: have the task prompt make the local model write the tests and the spoken cases too, turn fixes into small task prompts rather than editing by hand, and let the unattended queue (`/Voxa/.voxa-spec/issue102/queue.sh`, see [[voxa-issue-102-capability-loop]]) run for hours; my part is reading its one-line log and writing the next prompts.

**Repeated 2026-10-22 on the Dr. Mario Wii port:** "You are using WAY too many tokens. You're supposed to be delegating to strata." I had spent hours bisecting bugs myself (freeze, cache, timing) with many build/run cycles. How to apply: when a bug needs investigation, write the measured facts and a narrow task with a numeric gate for Strata after at most one or two quick checks; do not run my own bisect/instrument loops. My part is reading results, looking at frames and correcting wrong conclusions.

**Repeated again 2026-10-22 on CoinKitty** (started a wallet skeleton by hand): "You are supposed to use strata for almost everything, and then just check it's work and steer it differently when it's not working optimally." rhY asked for this to apply to every future session, so the rules now also live in the global `~/.claude/CLAUDE.md` (loaded whatever folder a session starts in). Launch Strata with `~/.local/bin/strata-opencode-starter`, not by hand.

**Harness (2026-10-24):** A/B on the same Strata Coder model, 8 replayed Voxa tasks x 2 rounds (`~/voxa-ab/`): pi passed 8/8 like OpenCode, one more first-try pass, ~30% less wall time, ~35% fewer tokens; its lean prompt keeps sessions small (largest real prompt 23K vs OpenCode 52K). Raising the compaction line from 48K to 52K changed nothing for either, so both stay at 48K. The Voxa runner (`/Voxa/.voxa-spec/tasks/agent/run-step.sh`) now uses `pi -p --no-session --offline --mode json` (json streams per step so the 3-minute hang guard works); `HARNESS=opencode` restores OpenCode. pi config: `~/.pi/agent/{models,settings}.json`.
