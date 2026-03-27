#!/usr/bin/env python3
import argparse
import html
import json
from pathlib import Path

CSS = """
body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; margin: 24px; line-height: 1.5; color: #111; }
.card { border: 1px solid #e5e7eb; border-radius: 12px; padding: 16px; margin: 0 0 14px 0; }
.title { font-size: 18px; font-weight: 700; margin-bottom: 8px; }
.meta { color: #666; font-size: 12px; margin-bottom: 8px; }
.link a { word-break: break-all; color: #2563eb; text-decoration: none; }
.badge { display:inline-block; padding: 2px 8px; border-radius: 999px; background:#ecfeff; color:#155e75; font-size:12px; margin-right:6px; }
small { color: #666; }
"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('json_path')
    ap.add_argument('output_html')
    ap.add_argument('--title', default='PanSou 搜索结果')
    args = ap.parse_args()

    data = json.loads(Path(args.json_path).read_text(encoding='utf-8'))
    items = data.get('items') or []
    keyword = data.get('keyword') or ''
    provider = data.get('provider') or ''

    cards = []
    for i, item in enumerate(items, 1):
        title = html.escape(item.get('title') or f'结果 {i}')
        url = html.escape(item.get('url') or '')
        password = html.escape(item.get('password') or '')
        source = html.escape(item.get('source') or '')
        dt = html.escape(item.get('datetime') or '')
        meta = ' '.join(x for x in [f'来源: {source}' if source else '', f'时间: {dt}' if dt else ''] if x)
        extra = f'<div><span class="badge">提取码 {password}</span></div>' if password else ''
        cards.append(f'''<div class="card">
  <div class="title">{i}. {title}</div>
  <div class="meta">{meta}</div>
  {extra}
  <div class="link"><a href="{url}">{url}</a></div>
</div>''')

    doc = f'''<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>{html.escape(args.title)}</title>
<style>{CSS}</style>
</head>
<body>
<h1>{html.escape(args.title)}</h1>
<p><small>关键词：{html.escape(keyword)} ｜ 网盘：{html.escape(provider)} ｜ 条数：{len(items)}</small></p>
{''.join(cards) if cards else '<p>暂无结果</p>'}
</body>
</html>'''

    out = Path(args.output_html)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(doc, encoding='utf-8')
    print(str(out))


if __name__ == '__main__':
    main()
