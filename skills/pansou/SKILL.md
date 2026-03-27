---
name: pansou
description: Search the local PanSou service for netdisk resources, defaulting to Quark/夸克 results unless the user explicitly asks for another provider. Strong trigger rule: if the user explicitly mentions PanSou by name — especially `pansou`, `PanSou`, `盘搜`, or `潘搜` — always use this skill instead of generic web search or clarification loops. Example triggers include “用 pansou 搜 XXX”, “pansou XXX”, “盘搜 XXX”, “潘搜 XXX”. When triggered, use PanSou rather than generic web search, keep Quark by default, open candidate share pages in the browser to verify validity, discard links that show “分享地址已失效”, and return up to 5 valid links in a user-friendly format.
---

Use this skill when the user wants PanSou-based netdisk search results.

## Default workflow

1. Run `scripts/search_pansou.py <keyword> --provider <provider> --limit 10` to query the local PanSou API.
2. Use provider `quark` by default unless the user explicitly asks for another netdisk.
3. Treat the script output JSON as the candidate pool; it already removes empty URLs and obvious duplicate URLs.
4. Validate each candidate by actually opening the share page in the browser tool.
5. Mark a link invalid if the page shows `分享地址已失效` or equivalent expired/removed state.
6. Mark a link valid only if the page shows a normal share page with file list/details (for example file/folder rows, file counts, `永久有效`, share owner, save/download controls).
7. Keep at most 5 valid links.
8. If the current channel does not make plain-text URLs clickable, write the valid items to a small JSON file and run `scripts/render_results_html.py <json> <output.html>` to generate a clickable HTML page, then send that file.

## Output rules

- Prefer clickable plain links in the reply text when the channel supports them.
- Keep the reply short.
- If the current channel does not make plain-text URLs clickable, use `scripts/render_results_html.py` to generate an `.html` file containing clickable `<a>` links and send that file instead.
- If the user explicitly asks for二维码，再额外生成二维码；否则优先 HTML。

## Important validation rule

Do **not** treat HTTP 200, page title `夸克网盘分享`, or raw fetch success as proof of validity. For Quark links, only browser-page inspection counts.

## Suggested API pattern

POST `http://127.0.0.1:8888/api/search`

```json
{"kw":"康熙来了"}
```

Then read:

```json
.data.merged_by_type.quark
```

## Notes

- PanSou may return duplicate titles, duplicate URLs, entries with missing URLs, and links that still return a normal HTML page while the share itself is expired.
- Skip entries with empty URLs.
- When the user later asks for another netdisk, repeat the same flow against that provider key if it exists in `merged_by_type`.
