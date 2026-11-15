---
name: strata-fleet
description: Since 2026-11-14 Strata runs continuously across all crhy repos via ~/strata-fleet/fleet.sh; Claude only monitors and pushes phone updates.
metadata:
  type: project
---
rhY 2026-11-14: Strata triages, fixes and implements issues across all GitHub repos, 99% of the work; Claude monitors and keeps rhY updated on their phone.
Runner ~/strata-fleet/fleet.sh (mate-terminal "Strata fleet"); STOP = `touch ~/strata-fleet/STOP`. Planner task f-plan reads inventory.md (open issues of repos.txt), writes tasks/fNNN-<repo>-<slug>.md + queue.txt, rejects go to skip.txt.
Each task: blobless clone in repos/<repo>, branch strata/fNNN, task's own Gate line; pass -> push branch (rhYgtaSA: main) + issue comment; fail -> local parked/ branch. No PRs.
Phone: comments on crhy/Strata#2 (status issue) + Claude's PushNotification via a Monitor on status.txt. Results: status.txt, fleet.log, gates/, tasks/notes-*.md.
rhYgtaSA's own day-queue stays stopped (.strata/STOP) while the fleet runs - only one pi window.
**Why:** one universal queue instead of per-project runners. **How to apply:** on resume, check status.txt tail, re-arm the Monitor, review parked tasks briefly. Related: [[claude-only-keeps-strata-going]], [[keep-strata-queue-deep]], [[rhygtasa-handoff]].
2026-11-15 ~10:40: rhY recording a video. STOP set; stop-for-video.sh stops the runner after f049 and kills the Strata server.
Resume when rhY says done: `rm ~/strata-fleet/STOP`, start Strata with `--model coder-iq1_m-ram` (256K; NOT plain coder-iq1_m = 64K),
then open the "Strata fleet" mate-terminal running fleet.sh (continues from pos: f047, f048, then planner). Gates run without
DISPLAY/DBUS; f027 merged to rhYciv master. Pending: rhY to post the f049 reply on spaced#420 and eyeball f040 ocean tiles.
