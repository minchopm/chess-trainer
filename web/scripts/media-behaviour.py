#!/usr/bin/env python3
"""Attach the media bucket to the distribution as a second origin.

Called by provision.sh, and idempotent: run it against a distribution that
already has the origin and it changes nothing.

Why a second bucket behind the *same* distribution, rather than the two obvious
alternatives:

  * Same bucket as the site — which is where this started. It works, but a
    deploy then walks eighteen hundred objects it did not build to decide it has
    nothing to do, and `PRUNE=1` is one forgotten `--exclude` away from deleting
    the lot.

  * A separate distribution on media.brasspawn.com — clean separation, and it
    puts a DNS lookup and a TLS handshake in front of the first frame of every
    film, on the connection least able to afford them. It also needs its own
    certificate, and it makes the media cross-origin for no gain.

  * A second origin on the same distribution, which is this. The URLs stay
    `/media/...` on the same host, so nothing about the page changes and there
    is nothing extra to negotiate. Media gets its own bucket, its own cache
    behaviour and its own lifecycle, and the site deploy physically cannot reach
    it.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys

DIST = os.environ['DIST']
BUCKET = os.environ['MEDIA_BUCKET']
OAC = os.environ['MEDIA_OAC']
REGION = os.environ.get('REGION', 'eu-central-1')
ORIGIN_ID = f'{BUCKET}-s3'

# CachingOptimized: AWS-managed, caches on the path alone, forwards no cookies
# and no query string. Exactly what an immutable file wants, and it means a
# stray `?utm_source=` cannot split the cache.
CACHE_POLICY = '658327ea-f89d-4fab-a63d-7e88639e58f6'


def aws(*args: str) -> str:
    done = subprocess.run(['aws', *args], capture_output=True, text=True)
    if done.returncode:
        sys.exit(f'aws {" ".join(args)}\n{done.stderr.strip()}')
    return done.stdout


def main() -> int:
    config = json.loads(aws('cloudfront', 'get-distribution-config', '--id', DIST))
    etag, dc = config['ETag'], config['DistributionConfig']
    domain = f'{BUCKET}.s3.{REGION}.amazonaws.com'
    changed = False

    origins = dc['Origins']['Items']
    if not any(o['Id'] == ORIGIN_ID for o in origins):
        # Copied from the site origin so that connection timeouts, retries and
        # protocol settings match, then pointed elsewhere.
        origin = dict(origins[0])
        origin.update({
            'Id': ORIGIN_ID,
            'DomainName': domain,
            'OriginAccessControlId': OAC,
            'OriginPath': '',
        })
        origins.append(origin)
        dc['Origins']['Quantity'] = len(origins)
        changed = True
        print(f'  origin added: {ORIGIN_ID} -> {domain}')

    behaviours = dc.setdefault('CacheBehaviors', {'Quantity': 0, 'Items': []})
    items = behaviours.setdefault('Items', [])
    if not any(b['PathPattern'] == '/media/*' for b in items):
        default = dc['DefaultCacheBehavior']
        items.append({
            'PathPattern': '/media/*',
            'TargetOriginId': ORIGIN_ID,
            'ViewerProtocolPolicy': 'redirect-to-https',
            'AllowedMethods': {
                'Quantity': 2, 'Items': ['GET', 'HEAD'],
                'CachedMethods': {'Quantity': 2, 'Items': ['GET', 'HEAD']},
            },
            'CachePolicyId': CACHE_POLICY,
            # No function here. The router rewrites extensionless paths to
            # index.html; every file under /media has an extension, so running
            # it would be work done on every request for a rule that can never
            # fire.
            'FunctionAssociations': {'Quantity': 0},
            'LambdaFunctionAssociations': {'Quantity': 0},
            # mp4, avif and webp are already compressed. Asking CloudFront to
            # try again costs CPU at the edge and saves nothing.
            'Compress': False,
            'SmoothStreaming': False,
            'FieldLevelEncryptionId': '',
            **({'ResponseHeadersPolicyId': default['ResponseHeadersPolicyId']}
               if default.get('ResponseHeadersPolicyId') else {}),
        })
        behaviours['Quantity'] = len(items)
        changed = True
        print('  cache behaviour added: /media/* ->', ORIGIN_ID)

    if not changed:
        print('  media origin and behaviour already present')
        return 0

    with open('/tmp/brasspawn-dist.json', 'w') as handle:
        json.dump(dc, handle)
    out = aws('cloudfront', 'update-distribution', '--id', DIST,
              '--if-match', etag,
              '--distribution-config', 'file:///tmp/brasspawn-dist.json')
    print('  distribution now', json.loads(out)['Distribution']['Status'],
          '— it takes a few minutes to reach every edge')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
