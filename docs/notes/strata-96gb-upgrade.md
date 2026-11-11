---
name: strata-96gb-upgrade
description: 2026-11-10 RAM 32->96 GB: what broke, what was found, the IQ3_S full-model install, harness changes, BIOS and DeepSeek verdicts
metadata:
  type: project
---
**Hardware (2026-11-10):** 7800X3D, RTX 4070 Ti SUPER 16 GB (PCIe 4.0 x16), TUF X670E-PLUS (BIOS 3883). RAM is now 4
mixed DIMMs: G.Skill 2x16 GB F5-6000J3040F16G (1R, EXPO 6000) + SK Hynix 2x32 GB HMCG88AGBUA081N (2R, JEDEC 5600).
dmidecode: **all four run at 3600 MT/s** (AMD's 2DPC fallback); measured ~50 GB/s aggregate copy.

**What broke Strata (pi):** asked how to use the new RAM, a Strata-in-pi session wrote strata-coder-iq1_m-ram.json
(128K, --kv-resident 32768, --prompt-cache 12) plus --prompt-cache-spread, a flag only the Strata-next build has, while
pointing exe at the stable engine (built 10-17) -> "unknown argument", every start failed; it had also made that config
the starter default and edited strata-pi. Fix: dropped that one flag (backup .bak-spread). Lesson: don't let Strata
edit its own launcher/configs unreviewed; check a new flag with `<exe> --help | grep -- --flag` before using it.

**Discoveries**
- Coder at 128K (vs 64K) runs better at once (fewer compactions) and at 63-80 tok/s even at 3600 MT/s: its decode
  expert-cache hit rate on the GPU is 84-86%, so RAM speed barely matters for it. See [[strata-context-lesson]].
- Strata's docs: 96 GB+ -> full-model **IQ3_S** (all 512 experts; "matches the full model"); the Coder keeps 256.
- Shard 2 (28.8 GB n-gram/PLE table) is identical for every original size and the Coder: reuse it (setup hardlinks it
  on the same filesystem; across drives a symlink works).
- `tools/iq_pack.py` writes no experts.bin by default: the engine reads experts from the GGUF itself, so the IQ3_S
  pack is 1.5 GB (built in 2 s), not +50 GB. Disk needed for IQ3_S = 54.8 GB shard 1 + 1.5 GB.
- The MTP draft dir (Strata-data/mtp/rt) is shared by all versions.
- Full model uses data/expert-profile.bin; the Coder uses expert-profile-coder.bin (expert ids differ).
- Both IQ3_S and the Coder run 262144 context (native max); KV int8 is small (~1.8 GB per 128K). Past 256K needs YaRN.
- DeepSeek V4.1-Flash (Strata 0.2.8+, separate strata-dsv41 engine): 239-274 GB disk, 121-155 GB of weights, reads its
  Engram table from SSD every token and expects NVMe -> not practical here (SATA, 96 GB); measured 4.7 tok/s on a
  64 GB + NVMe box. Would need a ~2 TB NVMe and ideally 128 GB+, still well below Qwen's speed.
- Avalon (llama.cpp fork, 88 GB IQ3_KS) still doesn't fit 96 GB with the desktop; deleted with ~/Avalon.

**Installed:** ~/models/Qwen38-Flash-Next/IQ3_S (shard 1 SHA-256 4c1eb2ce...; shard 2 = SYMLINK to the Coder's file
on /media/rhy/data: move it before ever deleting the Coder), pack in IQ3_S/pack. Config ~/Strata/strata-qwen-iq3_s.json:
262144 ctx, --kv int8, --kv-resident 32768, --resident-experts, --prompt-cache 12, spec 4, reasoning budget 8000.
coder-iq1_m-ram.json raised to 262144 (backup .bak-128k).

**Harness changes:** starter accepts qwen-iq3_s (default still coder-iq1_m-ram until IQ3_S passes a gate);
btop/nvtop off by default (--monitors; rhY uses Spaced Monitor); strata-pi-limits adds an unknown model to pi's
models.json and points settings.json defaultModel + compaction override at the served model. pi compaction override
for iq3_s: reserve 40000, keepRecent 60000. Still to do after the switch: task headers' "64k / 120-line reads" rule,
pi maxTokens 32K, watchdog warn threshold (~8 GB), more prompt-cache slots, --calibrate, default -> qwen-iq3_s.

**BIOS advice given:** Ai Overclock Tuner Manual (not EXPO), DDR5-5200 (then 5600; fallback 4800), VDD/VDDQ 1.25 V,
VDDSOC 1.20 V, Memory Context Restore on, Power Down off, then a full memtest86+ pass. Best fix: one matched 2x48 GB
DDR5-6000 CL30 kit. Do it after the IQ3_S baseline run at 3600. Swap: keep it (swappiness 1, unused, safety margin).

**Cleanup done (rhY's OK):** Avalon model + ~/Avalon, bigboy-backup-2026-09-24, Note10 firmware zip, Spaced 11.26
test-artifacts, swapfile-temp. Never touch OpenAirShips or Unreal Engine (rhY).

**Why:** rhY wants the smartest model the new RAM allows and a working Strata pi harness for it.
**How to apply:** switch to IQ3_S only after rhY says the Coder's current project is done; open the pi window
([[always-open-pi-window]]); gate with a real task. Supersedes the numbers in [[strata-ram-budget]].
