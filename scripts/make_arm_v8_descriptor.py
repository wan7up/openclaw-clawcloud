#!/usr/bin/env python3
import argparse
import json
import subprocess
import sys
from pathlib import Path


def sh(*args):
    return subprocess.check_output(args, text=True)


def main():
    parser = argparse.ArgumentParser(description='Generate an OCI descriptor that republishes an arm64 image as linux/arm/v8')
    parser.add_argument('--image', required=True, help='image ref, e.g. ghcr.io/wan7up/openclaw-arm64:2026.3.31-manual-devices-v8')
    parser.add_argument('--output', required=True, help='output json path')
    args = parser.parse_args()

    manifest = json.loads(sh('docker', 'buildx', 'imagetools', 'inspect', '--format', '{{json .Manifest}}', args.image))
    image_meta = json.loads(sh('docker', 'buildx', 'imagetools', 'inspect', '--format', '{{json .Image}}', args.image))

    if manifest.get('mediaType', '').endswith('image.index.v1+json'):
        if not manifest.get('manifests'):
            raise SystemExit(f'no manifests found in index for {args.image}')
        src = manifest['manifests'][0]
        media_type = src['mediaType']
        digest = src['digest']
        size = src['size']
    else:
        media_type = manifest['mediaType']
        digest = manifest['digest']
        size = manifest['size']

    arch = image_meta.get('architecture')
    os_name = image_meta.get('os')
    if arch != 'arm64' or os_name != 'linux':
        raise SystemExit(f'{args.image} is not linux/arm64 (got os={os_name}, arch={arch})')

    descriptor = {
        'mediaType': media_type,
        'digest': digest,
        'size': size,
        'platform': {
            'architecture': 'arm',
            'os': 'linux',
            'variant': 'v8',
        },
    }

    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(descriptor, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(descriptor, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    try:
        main()
    except subprocess.CalledProcessError as e:
        print(e.output, file=sys.stderr)
        raise
