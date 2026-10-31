#!/usr/bin/env bash
# A/B driver, second start: A's timings exist; run B, C, D, then the baseline A again (its gates were mis-scored).
set -uo pipefail
B=/media/rhy/data/strata-bench; Q=$HOME/supermox-strata-backlog.txt
TASKS="t62-gossip t58-overrides-check"
log() { echo "$(date +%T) $*" | tee -a $B/driver.log; }
health() { curl -s -m 3 localhost:8080/health | grep -q '"loaded": *true'; }
stop_server() {
  for p in $(pgrep -f 'serve/server.py --engine strata'); do kill "$p"; done
  for i in $(seq 60); do pgrep -f -- '--pack /media/rhy/data/Strata-data/packs' >/dev/null || break; sleep 2; done
  for p in $(pgrep -f -- '--pack /media/rhy/data/Strata-data/packs'); do kill "$p"; done; sleep 5
}
start_server() {
  timeout 900 $HOME/.local/bin/strata-opencode-starter --model "$1" --project $HOME/supermox --no-dialog --server-only < /dev/null >> $B/driver.log 2>&1
  for i in $(seq 120); do health && return 0; sleep 5; done; return 1
}
bench() { reps=2; [ "${1%-check}" != "$1" ] && reps=1; for rep in $(seq $reps); do $B/bench.sh "$1" $TASKS; done; }
S=$HOME/supermox-strata-status.txt
grep -vE '^\s*(#|$)' $Q > $B/backlog.parked; grep '^#' $Q > $Q.tmp && mv $Q.tmp $Q
log "backlog parked ($(wc -l < $B/backlog.parked) tasks); waiting for the running task to finish"
until tail -1 $S | grep -qE ' OK \(| did not pass | no changes'; do sleep 20; done
log "driver3 start: E = 0.1.54 with STRATA_ROUTE_TAIL_SKIP=0"
for cfg in coder-iq1_m-next-noskip:E-noskip coder-iq1_m:A-0.1.38-check; do
  model=${cfg%%:*}; label=${cfg##*:}
  log "switching to $model"; stop_server
  if start_server "$model"; then log "$model loaded; $(free -g | awk 'NR==2{print "RAM avail " $7 " GiB"}')"; bench "$label"
  else log "$model FAILED to load: see $HOME/Strata/strata-$model.log"; fi
done
health || { log "baseline not up: starting coder-iq1_m"; stop_server; start_server coder-iq1_m; }
cat $B/backlog.parked >> $Q; log "backlog restored; A/B done"; cat $B/results.txt
