# -*- coding: utf-8 -*-
"""Give the App Clip's card a line and a picture in every language.

Apple wants one localization per locale the listing has, each with its own
header image — so the same 1800 x 1200 goes up thirty-one times. It carries no
text on purpose, which is what lets one picture serve them all.

Create-or-update throughout, and safe to run again: a locale that already has
its line keeps it, and a header that is already delivered is not replaced.
"""
import pathlib
import sys

from asc import call
from clipcard import SUBTITLE
from clipheader import upload

RESOURCE = "appClipDefaultExperienceLocalizations"


def run(experience_id: str, header: pathlib.Path, only=None):
    existing = {x["attributes"]["locale"]: x for x in
                call("GET", f"/appClipDefaultExperiences/{experience_id}"
                            f"/{RESOURCE}?limit=200")["data"]}

    for locale in (only or sorted(SUBTITLE)):
        subtitle = SUBTITLE[locale]
        found = existing.get(locale)
        if found:
            if found["attributes"].get("subtitle") != subtitle:
                call("PATCH", f"/{RESOURCE}/{found['id']}", {"data": {
                    "type": RESOURCE, "id": found["id"],
                    "attributes": {"subtitle": subtitle}}})
            loc_id, what = found["id"], "updated"
        else:
            made = call("POST", f"/{RESOURCE}", {"data": {
                "type": RESOURCE,
                "attributes": {"locale": locale, "subtitle": subtitle},
                "relationships": {"appClipDefaultExperience": {
                    "data": {"type": "appClipDefaultExperiences", "id": experience_id}}}}})
            loc_id, what = made["data"]["id"], "created"

        image = call("GET", f"/{RESOURCE}/{loc_id}/appClipHeaderImage").get("data")
        delivered = (image or {}).get("attributes", {}).get("assetDeliveryState", {}).get("state")
        if delivered == "COMPLETE":
            print(f"  {locale:8} {what:7} header already there   {subtitle}")
            continue

        # The confirming PATCH has been seen to 500 once and succeed on a retry.
        for attempt in range(3):
            try:
                upload(header, loc_id)
                print(f"  {locale:8} {what:7} header uploaded      {subtitle}")
                break
            except SystemExit as error:
                if attempt == 2:
                    raise
                print(f"  {locale:8} retrying header ({str(error).splitlines()[1][:40]})")


if __name__ == "__main__":
    run(sys.argv[1], pathlib.Path(sys.argv[2]), sys.argv[3:] or None)
