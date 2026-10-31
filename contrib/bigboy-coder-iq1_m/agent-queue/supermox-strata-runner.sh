#!/usr/bin/env bash
# SuperMox Strata runner: takes tasks from a backlog file one at a time, so the queue never runs dry between batches.
# Add a task by appending its name (e.g. t56-foo, with .strata/t56-foo.md written first) to the backlog file.
# Refuses to start a task while the repo has uncommitted changes outside .strata/ (those would be swept into the
# task's commit or a parked branch).
S=/home/rhy/supermox-strata-status.txt
A=/home/rhy/supermox-alerts.txt
B=/home/rhy/supermox-strata-backlog.txt
R=/home/rhy/supermox
BR=strata-m1
G='out=$(bash scripts/check.sh 2>&1 | tail -5); echo "$out"; echo "$out" | tail -1 | grep -qx "All checks passed."'
touch "$B"
# Start after the numbered queues finish.
until grep -q 'MQUEUE30 END' "$S" 2>/dev/null; do sleep 30; done
echo "$(date +%F_%T) RUNNER START (backlog $B)" >> "$S"
while true; do
  t=$(grep -vE '^\s*(#|$)' "$B" | head -1)
  if [ -z "$t" ]; then sleep 60; continue; fi
  cd "$R" || exit 1
  if [ -n "$(git status --porcelain -- . ':!.strata')" ]; then
    printf '%s DIRTY TREE: not starting %s until uncommitted changes are committed\n' "$(date +%F_%T)" "$t" | tee -a "$A"
    until [ -z "$(git status --porcelain -- . ':!.strata')" ]; do sleep 60; done
  fi
  [ -f ".strata/$t.md" ] || { printf '%s MISSING TASK FILE .strata/%s.md, skipping\n' "$(date +%F_%T)" "$t" | tee -a "$A"; sed -i "0,/^$t\$/{/^$t\$/d}" "$B"; continue; }
  until curl -s -m 3 localhost:8080/health | grep -q '"loaded": *true'; do sleep 30; done
  sed -i "0,/^$t\$/{/^$t\$/d}" "$B"
  LOG=$R/.strata/log-$t.txt; echo "$(date +%T) START $t" >> "$S"
  timeout 6000 /home/rhy/.local/bin/pi -p --no-session --offline --mode json \
    "Read these two files with the read tool, then carry out the task they describe exactly: $R/.strata/_header.md , $R/.strata/$t.md" > "$LOG" 2>&1
  changed=$(git status --short | wc -l)
  if [ "$changed" -eq 0 ]; then echo "$(date +%T) $t finished, no changes" >> "$S"; continue; fi
  if bash -c "$G" > "$R/.strata/gate-$t.txt" 2>&1; then
    git add -A && git commit -q -m "$t (local model task, pending review)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"; echo "$(date +%T) $t OK ($changed paths changed)" >> "$S"
  else
    git checkout -q -b "failed/$t-$(date +%H%M%S)" && git add -A && git commit -q -m "Parked: $t did not pass its gate"; git checkout -q $BR
    echo "$(date +%T) $t did not pass ($(tail -1 "$R/.strata/gate-$t.txt" | cut -c1-90)): parked on a side branch, continuing" >> "$S"
  fi
  echo "$(date +%T) TASK DONE $t" >> "$A"
done
