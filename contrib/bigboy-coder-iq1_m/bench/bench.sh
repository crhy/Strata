#!/usr/bin/env bash
# Usage: bench.sh <label> <task> [<task>...]   Replays finished SuperMox tasks against the running Strata server.
# Each run: fresh worktree at the task's parent commit, header/task paths rewritten, pi run, gate, metrics from the server log.
set -euo pipefail
label=$1; shift
B=/media/rhy/data/strata-bench; R=/home/rhy/supermox; L=$HOME/.local/state/strata-opencode-starter/strata-server.log
declare -A PARENT=( [t62-gossip]=55b1d72 [t58-overrides-check]=b438277 [t63-dht-locator]=a3fb698 )
for t in "$@"; do
  run=$label-$t-$(date +%H%M%S); W=$B/wt-$run
  git -C $R worktree add -q --detach $W ${PARENT[$t]}
  ln -s $R/upstream $W/upstream; mkdir -p $W/build $W/.strata
  for f in _header.md $t.md; do sed "s#/home/rhy/supermox#$W#g" $R/.strata/$f > $W/.strata/$f; done
  off=$(stat -c %s $L); t0=$(date +%s)
  ( cd $W && timeout 2400 $HOME/.local/bin/pi -p --no-session --offline --mode json \
      "Read these two files with the read tool, then carry out the task they describe exactly: $W/.strata/_header.md , $W/.strata/$t.md" \
      > $B/log-$run.json 2>&1 ) || true
  t1=$(date +%s)
  # Replay worktrees always fail test-repo-layout (the upstream symlink) and test-build-iso (no Spaced build dir):
  # gate = the task's own test passes AND check.sh shows no other FAIL.
  case $t in
    t62-gossip) own="PYTHONPATH=src python3 -m unittest tests/py/test_gossip.py" ;;
    t58-overrides-check) own="bash tests/test-check-overrides.sh" ;;
    t63-dht-locator) own="PYTHONPATH=src python3 -m unittest tests/py/test_locator.py" ;;
  esac
  ownrc=0; (cd $W && bash -c "$own" > $B/gate-$run.txt 2>&1) || ownrc=$?
  (cd $W && bash scripts/check.sh >> $B/gate-$run.txt 2>&1) || true
  other=$( { grep '^FAIL' $B/gate-$run.txt || true; } | { grep -vE 'upstream|test-repo-layout|packages.chroot|test-build-iso' || true; } | wc -l)
  if [ $ownrc -eq 0 ] && [ $other -eq 0 ]; then gate=PASS; else gate="FAIL(own=$ownrc,other=$other)"; fi
  stats=$(tail -c +$((off+1)) $L | python3 -c '
import re,sys
out=0;gen=0.0;prompt=0;last=None;reqs=0
for l in sys.stdin:
    m=re.search(r"done: (\d+) tokens in (\d+) s",l)
    if m: out+=int(m[1]); gen+=float(m[2]); reqs+=1; continue
    m=re.search(r"reading the prompt: [\d,]+ of [\d,]+ tokens, (\d+) s",l)
    if m: last=int(m[1]); continue
    if last is not None and ("thinking" in l or "answering" in l or "writing a tool" in l): prompt+=last; last=None
print(f"requests={reqs} out_tokens={out} gen_s={gen:.0f} prompt_s={prompt}")')
  echo "$(date +%F_%T) $label $t wall_s=$((t1-t0)) gate=$gate $stats" | tee -a $B/results.txt
  git -C $R worktree remove --force $W
done
