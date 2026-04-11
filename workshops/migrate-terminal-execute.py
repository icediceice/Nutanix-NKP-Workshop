#!/usr/bin/env python3
"""Convert Educates terminal:execute blocks to plain bash blocks.

Usage: python3 workshops/migrate-terminal-execute.py [content-dir]

Default content-dir: workshops/nkp-workshop/workshop/content
"""
import re
import sys
from pathlib import Path

BLOCK_RE = re.compile(r'```terminal:execute\n(.*?)```', re.DOTALL)


def extract_command(yaml_body: str) -> str:
    lines = yaml_body.splitlines()
    cmd_lines = []
    in_cmd = False

    for line in lines:
        # Multiline block scalar: command: |
        if re.match(r'^command:\s*\|', line):
            in_cmd = True
            continue
        # Inline scalar: command: some text
        if re.match(r'^command:\s*\S', line) and not in_cmd:
            m = re.match(r'^command:\s*(.+)', line)
            return m.group(1).strip()
        if in_cmd:
            # Stop at next top-level key (e.g. session:)
            if re.match(r'^\w+:', line):
                break
            cmd_lines.append(line)

    if not cmd_lines:
        return yaml_body.strip()

    # Dedent: strip common leading whitespace
    non_empty = [l for l in cmd_lines if l.strip()]
    if non_empty:
        indent = min(len(l) - len(l.lstrip()) for l in non_empty)
        cmd_lines = [l[indent:] for l in cmd_lines]

    return '\n'.join(cmd_lines).strip()


def convert(content: str) -> str:
    def replacer(m):
        cmd = extract_command(m.group(1))
        return f'```bash\n{cmd}\n```'
    return BLOCK_RE.sub(replacer, content)


if __name__ == '__main__':
    target = Path(sys.argv[1]) if len(sys.argv) > 1 else \
             Path('workshops/nkp-workshop/workshop/content')

    changed = 0
    for f in sorted(target.glob('**/*.md')):
        original = f.read_text()
        converted = convert(original)
        if converted != original:
            f.write_text(converted)
            print(f'  converted: {f.name}')
            changed += 1

    print(f'\n{changed} file(s) updated')
