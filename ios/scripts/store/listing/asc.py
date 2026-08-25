#!/usr/bin/env python3
"""Talk to the App Store Connect API.

A thin wrapper: mint the JWT, then GET/PATCH/POST JSON. Everything the store
listing needs is one of those three.
"""
import json, os, sys, time, urllib.request, urllib.error

ISSUER = os.environ["ASC_ISSUER_ID"]
KEY_ID = os.environ["ASC_KEY_ID"]
KEY_PATH = os.path.expanduser(os.environ["ASC_KEY_PATH"])
BASE = "https://api.appstoreconnect.apple.com/v1"

_token = None
_token_born = 0


def token():
    global _token, _token_born
    if _token and time.time() - _token_born < 900:
        return _token
    import jwt  # PyJWT
    key = open(KEY_PATH).read()
    now = int(time.time())
    _token = jwt.encode(
        {"iss": ISSUER, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
        key,
        algorithm="ES256",
        headers={"kid": KEY_ID, "typ": "JWT"},
    )
    _token_born = time.time()
    return _token


def call(method, path, body=None):
    url = path if path.startswith("http") else BASE + path
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", "Bearer " + token())
    if data:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as r:
            raw = r.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        detail = e.read().decode()
        raise SystemExit(f"{method} {url}\nHTTP {e.code}\n{detail}")


if __name__ == "__main__":
    method = sys.argv[1].upper()
    path = sys.argv[2]
    body = json.loads(sys.argv[3]) if len(sys.argv) > 3 else None
    print(json.dumps(call(method, path, body), indent=1, ensure_ascii=False))
