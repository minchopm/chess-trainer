# -*- coding: utf-8 -*-
"""Upload the header image for an App Clip's default experience.

Same three-step asset dance as the review screenshots — reserve, PUT, confirm —
against a different resource. 1800 x 1200, and Apple is strict about it.

    python3 clipheader.py <png> <appClipDefaultExperienceLocalization id>
"""
import hashlib
import pathlib
import sys
import urllib.request

from asc import call

RESOURCE = "appClipHeaderImages"


def upload(path: pathlib.Path, localization_id: str) -> str:
    blob = path.read_bytes()
    made = call("POST", f"/{RESOURCE}", {"data": {
        "type": RESOURCE,
        "attributes": {"fileName": path.name, "fileSize": len(blob)},
        "relationships": {"appClipDefaultExperienceLocalization": {
            "data": {"type": "appClipDefaultExperienceLocalizations", "id": localization_id}}},
    }})
    asset_id = made["data"]["id"]

    for op in made["data"]["attributes"]["uploadOperations"]:
        chunk = blob[op["offset"]:op["offset"] + op["length"]]
        req = urllib.request.Request(op["url"], data=chunk, method=op["method"])
        for header in op["requestHeaders"]:
            req.add_header(header["name"], header["value"])
        urllib.request.urlopen(req).read()

    call("PATCH", f"/{RESOURCE}/{asset_id}", {"data": {
        "type": RESOURCE, "id": asset_id,
        "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(blob).hexdigest()},
    }})
    return asset_id


if __name__ == "__main__":
    png, loc = pathlib.Path(sys.argv[1]), sys.argv[2]
    print(f"uploaded {upload(png, loc)} ({png.stat().st_size} bytes)")
