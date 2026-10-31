#!/bin/bash
# SuperMox batch 30: finish branding (pi).
# Harness: pi (won the 2026-10-24 A/B against OpenCode on the same Strata model); --mode json streams, so the stall guard works.
S=/home/rhy/supermox-strata-status.txt
until grep -q "MQUEUE29 END" "$S" 2>/dev/null; do sleep 30; done
until curl -s -m 3 localhost:8080/health | grep -q '"loaded": *true'; do sleep 30; done
echo "$(date +%F_%T) MQUEUE30 START" >> $S
run() { R=$1; BR=$2; t=$3; GATE=$4; cd $R || return
  LOG=$R/.strata/log-$t.txt; echo "$(date +%T) START $t" >> $S
  timeout 6000 /home/rhy/.local/bin/pi -p --no-session --offline --mode json \
    "Read these two files with the read tool, then carry out the task they describe exactly: $R/.strata/_header.md , $R/.strata/$t.md" > "$LOG" 2>&1 &
  pid=$!; ( sleep 180; [ -s "$LOG" ] || kill $pid 2>/dev/null ) & guard=$!; wait $pid; kill $guard 2>/dev/null
  changed=$(git status --short | wc -l)
  if [ "$changed" -eq 0 ]; then echo "$(date +%T) $t finished, no changes" >> $S; return; fi
  if bash -c "$GATE" > $R/.strata/gate-$t.txt 2>&1; then
    git add -A && git commit -q -m "$t (local model task, pending review)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"; echo "$(date +%T) $t OK ($changed paths changed)" >> $S
  else
    git checkout -q -b "failed/$t-$(date +%H%M%S)" && git add -A && git commit -q -m "Parked: $t did not pass its gate"; git checkout -q $BR
    echo "$(date +%T) $t did not pass ($(tail -1 $R/.strata/gate-$t.txt | cut -c1-90)): parked on a side branch, continuing" >> $S
  fi
}

SM=/home/rhy/supermox
G='out=$(bash scripts/check.sh 2>&1 | tail -5); echo "$out"; echo "$out" | tail -1 | grep -qx "All checks passed."'
run $SM strata-m1 t53b-branding-finish "$G"
echo "$(date +%F_%T) MQUEUE30 END" >> $S
