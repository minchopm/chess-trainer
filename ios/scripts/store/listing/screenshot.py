# -*- coding: utf-8 -*-
"""Upload the App Review screenshot for an in-app purchase or a subscription.

Every purchase needs a picture of the screen that offers it before it can be
submitted, and without it the purchase — and so the app — cannot go for review.

Apple's asset upload is three steps and all three are needed: reserve, PUT the
bytes at the URL it hands back, then confirm with an MD5 of what was sent.
A reservation left unconfirmed looks exactly like no screenshot at all.

    python3 screenshot.py <png> subscription <id>
    python3 screenshot.py <png> iap <id>
"""
import hashlib
import pathlib
import sys
import urllib.request

from asc import call, token

KINDS = {
    "subscription": ("subscriptionAppStoreReviewScreenshots", "subscription", "subscriptions"),
    "iap": ("inAppPurchaseAppStoreReviewScreenshots", "inAppPurchaseV2", "inAppPurchases"),
}


def upload(path: pathlib.Path, kind: str, parent_id: str) -> str:
    resource, rel_name, rel_type = KINDS[kind]
    blob = path.read_bytes()

    made = call("POST", f"/{resource}", {"data": {
        "type": resource,
        "attributes": {"fileName": path.name, "fileSize": len(blob)},
        "relationships": {rel_name: {"data": {"type": rel_type, "id": parent_id}}},
    }})
    asset_id = made["data"]["id"]

    for op in made["data"]["attributes"]["uploadOperations"]:
        chunk = blob[op["offset"]:op["offset"] + op["length"]]
        req = urllib.request.Request(op["url"], data=chunk, method=op["method"])
        for header in op["requestHeaders"]:
            req.add_header(header["name"], header["value"])
        urllib.request.urlopen(req).read()

    call("PATCH", f"/{resource}/{asset_id}", {"data": {
        "type": resource,
        "id": asset_id,
        "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(blob).hexdigest()},
    }})
    return asset_id


if __name__ == "__main__":
    png, kind, parent = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3]
    print(f"{kind} {parent}: uploaded {upload(png, kind, parent)} ({png.stat().st_size} bytes)")
