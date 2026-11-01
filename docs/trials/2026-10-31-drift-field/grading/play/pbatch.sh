#!/bin/sh
# pbatch.sh <game>: every page scenario for one game
n=$1
for s in "field field1" "field field2" "drops drops" "speed speed" "speed speed-slow" "click click" "resize resize" "collide collide" "flow flow" "timeout timeout" "bestnow bestnow"; do
  set -- $s
  echo "== $n $1 $2 $(date +%T)"
  timeout 400 node run.cjs page $n $1 $2 > /dev/null 2>&1; echo "rc=$?"
done
