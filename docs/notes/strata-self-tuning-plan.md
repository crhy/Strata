---
name: strata-self-tuning-plan
description: Planned (not yet started): Strata tunes its own server flags via an outside harness; run only AFTER the first SuperMox beta release AND the Spaced app theming fixes
metadata:
  type: project
---

rhY (2026-10-31) wants an "AI makes itself faster" run like the Qwen3.8 Flash-Next/OpenCode story (36 s -> 23 s on the
same job; winners there: bigger prefill chunks + MTP guessing 3 ahead; no help from more threads, other model loading,
VRAM expert cache, KV squeezing, longer speculation). **Schedule: only after (1) the first SuperMox beta is released and
(2) all Spaced app theming is fixed (series th01-th06 + follow-ups).** Ask rhY before starting it then.

Design agreed: an outside harness (Strata cannot run while its server restarts). Loop: Strata proposes one flag set as
JSON (sees all past results) -> harness stops the server, restarts with those flags (from ~/Strata config, engine
~/Strata/engine/strata), waits for /health loaded -> speed benchmark = fixed replay of real pi requests (10-30K-token
prompts, temperature 0, total wall time) -> quality gate = fixed 20-question quiz with known answers (no score drop) ->
memory gate = one near-64K prompt with the watchdog/earlyoom watching (any OOM/crash rejects) -> keep best passing config,
restart on it, repeat. Tunables: --prefill auto/auto:16384/auto:32768, --spec N (now 4) and --spec-min-p, --expert-cache,
--kv int8/k8v4/q4_0, --prompt-cache / conversation-cache, --adapt-every, --pcie-frac. Constraint: Strata pins ~20.8 GB
RAM; ~2 GB headroom with Brave ([[strata-ram-budget]], [[brave-stays-open]]). Needs a 2-4 h quiet window with all queues
paused (~30-60 trials). Endpoint: report the winning config for rhY's OK before writing it into Strata's config.
