#!/usr/bin/env python3
import argparse
import json
import sys
import urllib.request
from urllib.error import URLError, HTTPError

API = 'http://127.0.0.1:8888/api/search'


def fetch(keyword: str):
    data = json.dumps({'kw': keyword}).encode('utf-8')
    req = urllib.request.Request(API, data=data, headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=20) as resp:
        return json.loads(resp.read().decode('utf-8', errors='replace'))


def dedupe(items):
    seen = set()
    out = []
    for item in items or []:
        url = (item or {}).get('url', '').strip()
        if not url or url in seen:
            continue
        seen.add(url)
        out.append(item)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('keyword')
    ap.add_argument('--provider', default='quark', help='merged_by_type provider key, default: quark')
    ap.add_argument('--limit', type=int, default=10)
    args = ap.parse_args()

    try:
        payload = fetch(args.keyword)
    except HTTPError as e:
        print(json.dumps({'ok': False, 'error': f'HTTP {e.code}: {e.reason}'}), ensure_ascii=False)
        sys.exit(2)
    except URLError as e:
        print(json.dumps({'ok': False, 'error': f'connect failed: {e.reason}'}), ensure_ascii=False)
        sys.exit(2)

    data = payload.get('data') or {}
    merged = data.get('merged_by_type') or {}
    items = dedupe(merged.get(args.provider) or [])
    items = items[: max(args.limit, 0)]

    result = {
        'ok': True,
        'provider': args.provider,
        'keyword': args.keyword,
        'count': len(items),
        'items': [
            {
                'title': (x.get('note') or '').strip(),
                'url': (x.get('url') or '').strip(),
                'password': (x.get('password') or '').strip(),
                'source': (x.get('source') or '').strip(),
                'datetime': (x.get('datetime') or '').strip(),
                'images': x.get('images') or [],
            }
            for x in items
        ],
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
