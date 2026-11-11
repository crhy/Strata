---
name: strata-ram-budget
description: "Strata holds ~20.8 GB of non-reclaimable RAM; with Brave open only ~2.4 GB headroom is left; running out freezes rhY's PC (2026-10-30)"
metadata:
  node_type: memory
  type: project
  originSessionId: fa019923-66a0-5cf5-8bde-ec7b0e7f1d77
  modified: 2026-10-31T06:51:51.378Z
---

The coder-iq1_m Strata engine (`--resident-experts`) copies every expert the GPU doesn't hold into locked RAM: 19.06 GiB, fixed by the model, not a tunable cache (shrinking it means reading from SSD at ~half speed). It shows as ~20.8 GB Shmem (not Mlocked). Measured 2026-10-30 right after load: Brave 5.2 GB + VSCodium 1.4 GB + desktop left only ~2.4 GB MemAvailable before any task ran. The memory is effectively non-reclaimable, so overflow freezes the machine hard instead of slowing down.

2026-10-30 23:14: the PC froze when pi compacted t70's 64K context while Strata's task was opening GTK test windows on rhY's real desktop via xdotool; swap had been 8-10 GB used all evening.

**Why:** two freezes so far; rhY has to reboot and loses running work.
**Superseded 2026-11-10:** RAM is now 96 GB; see [[strata-96gb-upgrade]]. Kept for history.

**How to apply:** with Brave open (it stays open, see [[brave-stays-open]]) there are ~2 GB of headroom; keep extra processes small while Strata runs (one VM max, no GUI tests on DISPLAY :0, see Supermox header rule 8); earlyoom (config in `/etc/default/earlyoom`, prefers killing pi/node/opencode; pi's process name is `pi`) and the watchdog's pi-task abort are the safety nets, not a budget. Related: [[watch-strata-speed]], [[tmp-is-ram-on-this-machine]], [[no-desktop-automation]].
