#!/usr/bin/env python3
"""Remove remaining Educates-specific content blocks from workshop markdown.

Handles:
  1. ```dashboard:open-url``` → bash echo of the URL (copy-to-clipboard friendly)
  2. ```examiner:execute-test``` → removed entirely
  3. %ingress_domain% / %session_name% / %session_namespace% → shell env vars

Usage: python3 workshops/migrate-educates-content.py [content-dir]
"""
import re
import sys
from pathlib import Path

DASHBOARD_RE = re.compile(r'```dashboard:open-url\n(.*?)```', re.DOTALL)
EXAMINER_RE  = re.compile(r'```examiner:execute-test\n.*?```\n?', re.DOTALL)


def convert_dashboard(yaml_body: str) -> str:
    name_m = re.search(r'^name:\s*(.+)$', yaml_body, re.MULTILINE)
    url_m  = re.search(r'^url:\s*(.+)$',  yaml_body, re.MULTILINE)
    name = name_m.group(1).strip() if name_m else 'Dashboard'
    url  = url_m.group(1).strip()  if url_m  else ''
    url  = url.replace('%session_name%',      '$SESSION_NAME') \
              .replace('%session_namespace%',  '$SESSION_NS') \
              .replace('%ingress_domain%',     '$INGRESS_DOMAIN')
    return f'Open **{name}** — run in terminal to get the URL:\n\n```bash\necho "{url}"\n```'


def convert(content: str) -> str:
    content = DASHBOARD_RE.sub(lambda m: convert_dashboard(m.group(1)), content)
    content = EXAMINER_RE.sub('', content)
    content = content.replace('%ingress_domain%',    '$INGRESS_DOMAIN') \
                     .replace('%session_name%',      '$SESSION_NAME') \
                     .replace('%session_namespace%', '$SESSION_NS')
    return content


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
