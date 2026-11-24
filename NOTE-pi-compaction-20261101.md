# Note: pi auto-compaction fix on this PC (2026-11-01)

Symptom: `Auto-compaction failed: Summarization failed: generation hit the token cap and the summary is incomplete`.

Cause: pi's summary call is cut off by its own output cap, and pi treats a cut-off summary as an error
(`stopReason === "length"`). Measured on pi 1.4.0 with `qwen3.8-flash-next-coder-iq1_m` at 65536 context:

- pi sends `max_tokens = maxTokens` from `~/.pi/agent/models.json`, which was **8192** - also for the summary call.
  Proof in the session logs: several turns end with `stopReason: "length"` and `output: 8192` exactly.
- The summary body of a 37k-token conversation needs 5.6-6.8k tokens (compaction entries: 17k-27k chars of summary
  text at 5852-8750 output tokens), and `reasoning_budget_tokens: 3000` in `strata-coder-iq1_m.json` spends 2-3k
  of the same 8192 on reasoning. Content + reasoning ≈ 9-10k > 8192 → `finish_reason: length`.
- pi 1.4.0 removed the old fixed 2048-token summary cap (issues #9512, #9075) and now uses the model's output
  limit, which is why 8192 became reachable.

Changed on this machine:

- `/home/rhy/.pi/agent/models.json`: `maxTokens` 8192 → **16384** (backup: `models.json.bak-maxtokens8192`).
  Checked against the running server: `max_tokens: 16384` is accepted, and `fit_max_tokens: true` in
  `strata-coder-iq1_m.json` clamps the cap to the room left in the 65536 context instead of returning 400.
- `/home/rhy/.pi/agent/settings.json` (earlier, unchanged now): `compaction.keepRecentTokens` 4000 → **12000**
  (backup: `settings.json.bak-keep4000`); `compaction` is `{ enabled: true, reserveTokens: 16384,
  keepRecentTokens: 12000 }`,
  so auto-compaction starts at 65536 - 16384 = 49152 context tokens (observed `tokensBefore`: 49156-58341).

Not changed, but the other levers if it comes back: lower `reasoning_budget_tokens` in
`/home/rhy/Strata/strata-coder-iq1_m.json` (reasoning tokens are paid out of the same output budget), or raise
`compaction.keepRecentTokens` further so less has to be summarized. pi's `compaction.modelOverrides` only accepts
`reserveTokens` and `keepRecentTokens`, not an output cap.

A running pi session has to be restarted (or `/model` reloaded) to pick up `models.json`.

## 2026-11-01 follow-up: the cap is the context room, not just `maxTokens`

Raising `maxTokens` to 16384 was necessary but not sufficient. Measured from
`/home/rhy/Strata/strata-coder-iq1_m.log` (25 MB, this machine):

- Largest prompts the server saw: **64413, 64479, 64797** tokens. With `fit_max_tokens: true` the output cap is
  clamped to the room left, so those requests had **65536 - 64797 = 739** tokens of output room. No summary of a
  37k-token conversation fits in 739 tokens.
- Largest completions in the same log: **8192** tokens, five times - the old `maxTokens` cap, hit exactly.
- No server-side output cap. The launch line is
  `/home/rhy/Strata/.venv/bin/python /home/rhy/Strata/serve/server.py --engine strata --config strata-coder-iq1_m.json
  --port 8080`, and `strata-coder-iq1_m.json` has no `-n` / `--n-predict` / `max_tokens` entry. `n_predict` is taken
  from the request (`serve/server.py` lines 2326, 2420, 2481: `0/-1: the rest`), so pi's `maxTokens` is the only cap.
- Only one quant on disk: `/media/rhy/data/Models/Qwen38-Flash-Next/` contains just `coder-IQ1_M`, and
  `/media/rhy/data/Strata-data/packs/` just `coder-iq1_m`. A better summarizer quant means downloading one.

So the summarization input is the problem: auto-compaction at 49152 context tokens hands a ~37k-token body to an
IQ1_M model that rambles at that length and never closes the summary. Smaller input is the fix, not a bigger output
budget.

Changed on this machine (2026-11-01, later in the day):

- `/home/rhy/.pi/agent/settings.json`: `compaction` is now **`{ "enabled": false }`** (backup:
  `settings.json.bak-autocompact`). Compaction is done by hand with `/compact <instruction>` around 40% of the
  window, or `/new` with a short handoff when a task wraps. pi still allows `/compact` with auto-compaction off
  (docs/compaction.md: "Disable auto-compaction with `"enabled": false`. You can still compact manually with
  `/compact`.").
- If auto-compaction is re-enabled, set it to trigger early instead of late: `reserveTokens: 40000` (triggers at
  65536 - 40000 = 25536 context tokens) and `keepRecentTokens: 6000` (summarized span ~19k, leaving ~46k of output
  room). Verified names: `compaction.enabled`, `reserveTokens`, `keepRecentTokens`, `modelOverrides` (the last
  accepts only the two token budgets, no output cap).

Keeping tool output small is what stops the window filling in the first place: pipe noisy commands through
`| tail -30`. pi truncates tool results to 2000 characters when serializing for the summary, but the live context
still carries the full output.


Written up in [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) and the table in
[docs/DETAILS.md](docs/DETAILS.md#troubleshooting).
