#!/bin/sh
# nrun.sh <game> <scenario> [tag]: runs a scenario natively on the private display
cd /tmp/claude-1000/-home-rknopf-projects-github-whirlinggizmo-helix-2-0/60669423-441a-4b69-b693-33655c8d5ced/scratchpad/trial-2d-run/grading/play && exec timeout 600 python3 /tmp/claude-1000/-home-rknopf-projects-github-whirlinggizmo-helix-2-0/60669423-441a-4b69-b693-33655c8d5ced/scratchpad/trial-2d-run/grading/run_native.py /tmp/claude-1000/-home-rknopf-projects-github-whirlinggizmo-helix-2-0/60669423-441a-4b69-b693-33655c8d5ced/scratchpad/trial-2d-run/grading/play node run.cjs native "$@"
