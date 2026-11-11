#!/usr/bin/env python3
"""Watches a job running in the background, for the person or agent following it: a status line every --every seconds, and a line the
moment the job ends, stalls or runs past its deadline, so nobody waits on a job that will never finish.

    python3 tools/watch_job.py PID LOG [--name NAME] [--every 600] [--stall 900] [--deadline SECONDS] [--exit-on-trouble]

PID is the job's process (a process id, never a pattern: a pattern matches the shell watching it, so a job that ended looks alive). LOG is
the file it writes to. Each status line starts with the Eastern time, then the job's name (default the log's), whether it runs, and the
log's last line:

    02:41 EST | windows tests: running, 34 min; last: - SDL_mixer.c

A job whose log hasn't changed for --stall seconds is reported STALLED, once each time it stalls; one running past --deadline seconds
(none by default) is reported OVERDUE, once. Either means look at the job and stop it if it's stuck, then go on with the work that
doesn't need it. When the job ends the last line says so and the tool exits 0.

Run it twice for a job an agent follows: under a watcher that turns each line into a notification (Claude Code's Monitor, re-armed when
it expires) for the status lines, and as a background command with --exit-on-trouble, which exits at the job's end (0), a stall (3) or
its deadline (4). A background command doesn't expire and its exit always wakes the session, so a lapsed watcher loses only the status
lines, never the stall. In a terminal, once is enough. Linux and macOS (it signals the process to see it's
there). Standard library only."""
import os
import sys
import time
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

sys.path.insert(0, str(Path(__file__).resolve().parent))
import cli


def alive(pid):
    """Whether the process is there (a zombie counts as gone)."""
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    try:
        return Path(f'/proc/{pid}/stat').read_text().split(') ')[-1][0] != 'Z'
    except OSError:
        return True


def last_line(log):
    """The log's last line that has text, shortened, or nothing."""
    try:
        with open(log, 'rb') as f:
            f.seek(0, 2)
            f.seek(max(0, f.tell() - 4096))
            lines = [l.strip() for l in f.read().decode('utf-8', 'replace').replace('\r', '\n').split('\n') if l.strip()]
    except OSError:
        return '(no log yet)'
    return (lines[-1][:100] if lines else '(log empty)')


def span(seconds):
    """A time span as people say it: seconds under a minute, then minutes."""
    return f'{int(seconds)} s' if seconds < 60 else f'{int(seconds // 60)} min'


def say(text):
    """One line, with the Eastern time first."""
    print(f'{datetime.now(ZoneInfo("America/New_York")).strftime("%H:%M %Z")} | {text}', flush=True)


def main():
    parser = cli.parser(__doc__)
    parser.add_argument('pid', type=int)
    parser.add_argument('log', type=Path)
    parser.add_argument('--name')
    parser.add_argument('--every', type=int, default=600, help='seconds between status lines (default 600)')
    parser.add_argument('--stall', type=int, default=900, help="seconds of an unchanged log that make the job STALLED (default 900)")
    parser.add_argument('--deadline', type=int, help='seconds after which a job still running is OVERDUE (default none)')
    parser.add_argument('--exit-on-trouble', action='store_true', help='exit at a stall (3) or the deadline (4), not only at the end')
    a = parser.parse_args()
    name = a.name or a.log.stem
    start = time.time()
    next_status = start
    stalled = overdue = False
    while True:
        now = time.time()
        running = alive(a.pid)
        if not running:
            say(f'{name}: ended after {span(now - start)}; last: {last_line(a.log)}')
            return 0
        try:
            quiet = now - a.log.stat().st_mtime
        except OSError:
            quiet = now - start
        if quiet > a.stall and not stalled:
            say(f'{name}: STALLED, its log unchanged for {span(quiet)}; last: {last_line(a.log)}')
            if a.exit_on_trouble:
                return 3
        stalled = quiet > a.stall
        if a.deadline and now - start > a.deadline and not overdue:
            say(f'{name}: OVERDUE, running {span(now - start)}, past its {span(a.deadline)}; last: {last_line(a.log)}')
            overdue = True
            if a.exit_on_trouble:
                return 4
        if now >= next_status:
            say(f'{name}: running, {span(now - start)}; last: {last_line(a.log)}')
            next_status = now + a.every
        time.sleep(min(15, a.every))


if __name__ == '__main__':
    sys.exit(main())
