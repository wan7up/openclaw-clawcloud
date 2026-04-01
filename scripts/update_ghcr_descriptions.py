#!/usr/bin/env python3
import base64
import mimetypes
from pathlib import Path

import requests

OWNER = "wan7up"
PACKAGES = {
    "openclaw-clawcloud": Path('.github/ghcr-openclaw-clawcloud.md'),
    "openclaw-arm64": Path('.github/ghcr-openclaw-arm64.md'),
}


def main():
    token = __import__('os').environ.get('GH_TOKEN') or __import__('os').environ.get('GITHUB_TOKEN')
    if not token:
        raise SystemExit('GH_TOKEN or GITHUB_TOKEN is required')

    session = requests.Session()
    session.headers.update({
        'Authorization': f'Bearer {token}',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
    })

    for package, path in PACKAGES.items():
        body = path.read_text(encoding='utf-8')
        payload = {'package_type': 'container', 'name': package, 'visibility': 'public'}

        # description is stored in package metadata through package PATCH API
        r = session.patch(
            f'https://api.github.com/users/{OWNER}/packages/container/{package}',
            json={'description': body.splitlines()[2] if len(body.splitlines()) > 2 else package},
        )
        if r.status_code not in (200, 201):
            print(f'WARN patch description failed for {package}: {r.status_code} {r.text}')
        else:
            print(f'updated description: {package}')

        rendered = base64.b64encode(body.encode('utf-8')).decode('ascii')
        r2 = session.put(
            f'https://api.github.com/repos/{OWNER}/openclaw-clawcloud/contents/.github/{path.name}',
            json={
                'message': f'chore(ghcr): update {package} package description source',
                'content': rendered,
            },
        )
        if r2.status_code not in (200, 201):
            print(f'INFO content sync skipped/failed for {package}: {r2.status_code}')


if __name__ == '__main__':
    main()
