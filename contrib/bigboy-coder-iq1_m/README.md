# Coder IQ1_M on a 32 GB PC with a 16 GB card, sysvinit host, pi agent

A working Strata setup for unattended coding agents on modest hardware, with the configs, launcher, agent queue and
an engine A/B benchmark (0.1.38 against 0.1.54) measured on real agent tasks.

## The machine

| Part | |
| --- | --- |
| CPU | AMD Ryzen 7 7800X3D (8 cores) |
| RAM | 32 GB (about 21 GB goes to the engine) |
| GPU | NVIDIA RTX 4070 Ti SUPER 16 GB, CUDA 13.4 |
| OS | Devuan (sysvinit + elogind, no systemd) |
| Model | Qwen3.8-Flash-Next **Coder** IQ1_M (`Qwen3.8-Flash-Next-GSQ-RCO-IQ1_M-0000{1,2}-of-00002.gguf`, 58 GB on disk, model and PLE table on a SATA SSD) |
| Engine | 0.1.38 (source build, CUDA arch 89) plus the elogind cgroup fix below |
| Agent | pi in print mode (`pi -p --no-session --offline --mode json`) |

Why the Coder: upstream's [MODELS.md](../../docs/MODELS.md) says a 32 GB PC with a 12 to 16 GB card runs the Coder. Q2_0,
IQ2_XS (Swift 1.5 included) and Gyro-M need 35 GB or more of experts in RAM and would stream from the SSD here.

## Files

| Path | What it is |
| --- | --- |
| `configs/strata-coder-iq1_m.json` | The production config (`serve/server.py --config`). Key flags: `--expert-cache auto --prefill auto --spec 4 --spec-min-p 0.5 --mtp ... --max-context 65536 --kv int8 --resident-experts`, `reasoning_budget_tokens: 3000`. |
| `configs/strata-coder-iq1_m-next*.json` | The A/B arms on engine 0.1.54 (paths point at a separate build in `/media/rhy/data/Strata-next`). `-noskip` shows how a config sets engine environment variables (`"env"`). |
| `configs/expert-profile-coder-learned.bin` | The expert profile the server learned over weeks of coding-agent work (`--expert-profile-save`). Start from it with `--expert-profile` on the same model. |
| `pi/models.json`, `pi/settings.json` | pi's provider entry for the Strata server (OpenAI-compatible, 65,536 context, 8,192 max output) and its defaults (compaction on, reserve 16K, keep 4K). Copy to `~/.pi/agent/`. |
| `launcher/strata-opencode-starter` | Starts the server in its own terminal (plus btop/nvtop/OpenCode windows), checks RAM, sets OpenCode's limits from the config, waits for `/health`, starts the memory watchdog. `--model coder-iq1_m[-variant] --project DIR --no-dialog [--server-only]`. Paths at the top are this machine's. |
| `launcher/memory-watchdog` | Desktop notification when swap runs low while the engine runs. |
| `agent-queue/supermox-strata-runner.sh` | Unattended runner: takes task names from a backlog file, runs pi on `<repo>/.strata/_header.md` + `<task>.md`, runs the repo's gate, commits on pass, parks failures on a side branch. |
| `agent-queue/supermox-strata-pi-queue30.sh` | The older numbered-batch form of the same, with a stall guard (kills a run with no output after 3 minutes). |
| `bench/` | The A/B harness and raw results (below). |
| `strata-cgroup-elogind.patch` | The engine fix below as a plain diff. |

## Measured speed (production config, engine 0.1.38)

- Decode about 60 to 84 tok/s while writing code (MTP draft 4); roughly 63 tok/s averaged over whole agent tasks.
- Prompt reading is a small share for an agent: over 300 consecutive pi requests, 681 s reading prompts against 2,158 s
  generating. The checkpoint cache already resumes most prompts near their end (a 42K-token prompt read in about 2 s);
  the slow reads are new tool output.
- Below about 50 tok/s means memory pressure (browser tabs, a VM): check `free` and close something.

## Engine A/B: 0.1.38 against 0.1.54 on real agent tasks (2026-10-30)

Method (`bench/bench.sh`, drivers in `bench/driver*.sh`): replay two finished tasks from a real project, each from a
fresh git worktree at the task's parent commit, through the same pi command the queue uses. Score = the task's own
tests pass and the project gate shows no new failures. Every arm was started with the launcher; same model, same
profile, same context. A ran 5 times per task (spread over the afternoon), the others twice.

| Arm | t62 wall (avg) | t58 wall (avg) | Decode | Output tokens, t62 | Gate |
| --- | ---: | ---: | ---: | ---: | --- |
| A: 0.1.38, production config | **239 s** | **342 s** | ~63 tok/s | ~12K | all pass |
| B: 0.1.54, same flags | 438 s | (lost to a harness bug) | not logged | ~27K | pass |
| C: 0.1.54 + `--prompt-cache-spread` | 360 s | 409 s | **~82 tok/s** | ~25K | all pass |
| D: C + `--kv k8v4` | 374 s | 538 s | ~79 tok/s | ~25K | all pass |
| E: 0.1.54, `STRATA_ROUTE_TAIL_SKIP=0` | 277 s | 400 s | ~72 tok/s | ~17K | all pass |

What it shows on this hardware and model:

- 0.1.54 decodes about 30% faster per token, but the agent does about twice the work: more turns (40 to 51 against 25
  to 35 on t62) and 30 to 50% more thinking per turn. Whole tasks get slower.
- Most of that comes from `STRATA_ROUTE_TAIL_SKIP=7`, on by default in 0.1.54 (its log line says answers "differ slightly from 0.1.41"). Turning it
  off (E) brings the work back toward 0.1.38 but keeps only part of the speed; E is still about 16% slower per task.
  On a 1-bit quant the skipped experts seem to matter more than on IQ3_XXS.
- `--prompt-cache-spread` changed nothing measurable: pi appends to its history, and prompt reading was 2 to 13 s per task.
- `--kv k8v4`: no measurable gain at 64K context.
- Two runs per arm is little; A alone ranged 188 to 336 s on one task. Treat 10 to 20% differences as indicative.

Decision for this machine: stay on 0.1.38 with the production config.

## Engine fix: elogind sessions on sysvinit hosts read "RAM unknown"

On a cgroup v2 host without systemd (elogind), a session's cgroup has no `memory.max` because the parent leaves the
memory controller off. The engine treated that as an unreadable limit and fell back to "RAM unknown". The fix: a group
without `memory.max` (and with `cgroup.controllers`) has no limit at that level; an existing but unreadable
`memory.max` still fails. Branches on this fork: `fix-elogind-cgroup` (on 0.1.38, with a test) and
`fix-elogind-cgroup-0.1.54` (the same commit on upstream 0.1.54, where the bug is still present).
