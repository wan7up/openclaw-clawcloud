#!/usr/bin/env python3
import argparse
import json
import re
import sys
import urllib.request
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parent.parent
STATE_PATH = WORKSPACE / 'memory' / 'openclaw-package-baselines.json'

TARGETS = {
    'clawcloud': {
        'dockerfile': WORKSPACE / 'deploy' / 'clawcloudrun-openclaw' / 'Dockerfile',
        'image_repo': 'ghcr.io/wan7up/openclaw-clawcloud',
        'baseline_tag': 'v2026.4.2-pluginfix-20260406-2',
        'tag_style': 'rebuild-from-validated-template',
        'template_base_version': '2026.4.2',
    },
    'arm64': {
        'dockerfile': WORKSPACE / 'deploy' / 'openclaw-arm64' / 'Dockerfile',
        'dockerfile_slim': WORKSPACE / 'deploy' / 'openclaw-arm64' / 'Dockerfile.slim',
        'image_repo': 'ghcr.io/wan7up/openclaw-arm64',
        'baseline_tag': '2026.4.2-official-min-rc1',
        'tag_style': 'upstream-official-min',
    },
}


def fetch_latest_release():
    url = 'https://api.github.com/repos/openclaw/openclaw/releases/latest'
    req = urllib.request.Request(url, headers={'User-Agent': 'openclaw-package-sync'})
    with urllib.request.urlopen(req, timeout=20) as resp:
        data = json.load(resp)
    tag = data['tag_name']
    upstream_version = tag[1:] if tag.startswith('v') else tag
    return {
        'repo': 'openclaw/openclaw',
        'release_tag': tag,
        'upstream_version': upstream_version,
        'published_at': data.get('published_at'),
        'release_name': data.get('name'),
        'html_url': data.get('html_url'),
    }


def load_state():
    if STATE_PATH.exists():
        return json.loads(STATE_PATH.read_text())
    return {'targets': {}}


def save_state(state):
    STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    STATE_PATH.write_text(json.dumps(state, ensure_ascii=False, indent=2) + '\n')


def replace_line(path: Path, pattern: str, repl: str):
    text = path.read_text()
    new_text, count = re.subn(pattern, repl, text, count=1, flags=re.M)
    if count != 1:
        raise RuntimeError(f'failed to update {path}: pattern not found -> {pattern}')
    path.write_text(new_text)


def sync_files(clawcloud_version: str, arm64_version: str):
    replace_line(
        TARGETS['clawcloud']['dockerfile'],
        r'^ARG BASE_IMAGE=.*$',
        f'ARG BASE_IMAGE=ghcr.io/openclaw/openclaw:{clawcloud_version}',
    )
    replace_line(
        TARGETS['arm64']['dockerfile'],
        r'^ARG OPENCLAW_VERSION=.*$',
        f'ARG OPENCLAW_VERSION={arm64_version}',
    )
    replace_line(
        TARGETS['arm64']['dockerfile_slim'],
        r'^ARG OPENCLAW_VERSION=.*$',
        f'ARG OPENCLAW_VERSION={arm64_version}',
    )


def main():
    parser = argparse.ArgumentParser(description='Sync task 001 / task 004 package bases to latest OpenClaw release')
    parser.add_argument('--version', help='override upstream version, e.g. 2026.3.31')
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()

    release = fetch_latest_release() if not args.version else {
        'repo': 'openclaw/openclaw',
        'release_tag': f"v{args.version}",
        'upstream_version': args.version,
        'published_at': None,
        'release_name': f'openclaw {args.version}',
        'html_url': f'https://github.com/openclaw/openclaw/releases/tag/v{args.version}',
    }

    state = load_state()
    current = state.get('upstream_version')
    clawcloud_version = release['upstream_version']
    arm64_version = release['upstream_version']
    changed = current != release['upstream_version']

    result = {
        'changed': changed,
        'from_version': current,
        'to_version': release['upstream_version'],
        'release_tag': release['release_tag'],
        'published_at': release.get('published_at'),
        'targets': {
            'clawcloud': {
                'baseline_tag': TARGETS['clawcloud']['baseline_tag'],
                'template_base_version': TARGETS['clawcloud']['template_base_version'],
                'next_image_tag_suggestion': f"v{clawcloud_version}",
            },
            'arm64': {
                'baseline_tag': TARGETS['arm64']['baseline_tag'],
                'next_image_tag_suggestion': f"{arm64_version}-official-min",
            },
        },
    }

    if args.dry_run:
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return

    sync_files(clawcloud_version, arm64_version)
    state.update(release)
    state['targets'] = {
        name: {
            key: value
            for key, value in cfg.items()
            if key in {'image_repo', 'baseline_tag', 'tag_style', 'template_base_version'}
        }
        for name, cfg in TARGETS.items()
    }
    save_state(state)
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f'[sync_openclaw_package_bases] {e}', file=sys.stderr)
        sys.exit(1)
