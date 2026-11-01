"""Writes each agent's compiles, from its transcript, to agent-N/compiles.md, and prints every tool call it made, to check what it read."""
import json, sys
from pathlib import Path
TASKS = Path('/tmp/claude-1000/-home-rknopf-projects-github-whirlinggizmo-helix-2-0/60669423-441a-4b69-b693-33655c8d5ced/tasks')
RUN = Path(__file__).resolve().parents[1]
AGENTS = {1: 'a889722fef3833490', 2: 'a3c7ec0ff27e03f0f', 3: 'a0b0dc0471cb36823'}
def text(content):
    if isinstance(content, str): return content
    return '\n'.join(c.get('text', '') for c in content if isinstance(c, dict))
for n, id in AGENTS.items():
    uses, results = [], {}
    for line in (TASKS / (id + '.output')).read_text().splitlines():
        try: entry = json.loads(line)
        except ValueError: continue
        message = entry.get('message') or {}
        content = message.get('content')
        if not isinstance(content, list): continue
        for c in content:
            if c.get('type') == 'tool_use': uses.append(c)
            elif c.get('type') == 'tool_result': results[c['tool_use_id']] = text(c.get('content', ''))
    out = [f'# Agent {n}: every compile, in order, with its whole output\n']
    count = 0
    print(f'--- agent {n}')
    for u in uses:
        i = u['input']
        print(' ', u['name'], (i.get('command') or i.get('file_path') or i.get('pattern') or '')[:160].replace('\n', ' '))
        if u['name'] == 'Bash' and 'haxe build-web.hxml' in i.get('command', ''):
            count += 1
            out.append(f'## Compile {count}\n\n```\n{results.get(u["id"], "(no result)").strip() or "(no output: a clean build)"}\n```\n')
    (RUN / f'agent-{n}' / 'compiles.md').write_text('\n'.join(out))
    print(f'  compiles: {count}')
