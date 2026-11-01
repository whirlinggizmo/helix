#!/bin/sh
# nbatch.sh <games...>: every native scenario, one at a time on the private display
for n in "$@"; do
for s in "field field1" "field field2" "drops drops" "speed speed" "speed speed-slow" "click click" "resize resize" "collide collide" "flow flow" "timeout timeout" "bestnow bestnow"; do
  set -- $s
  echo "== $n $1 $2 $(date +%T)"
  ./nrun.sh $n $1 $2 > /dev/null 2>&1; echo "rc=$?"
done
done
