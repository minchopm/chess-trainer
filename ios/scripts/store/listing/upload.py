# -*- coding: utf-8 -*-
"""Push the whole listing — every locale — through the App Store Connect API.

Two objects carry it. `appInfoLocalizations` hold the name, the subtitle and
the privacy policy: they belong to the app and survive versions.
`appStoreVersionLocalizations` hold the description, the keywords, the
promotional text and the URLs, and belong to version 1.0.

Both are create-or-update: Apple rejects a POST for a locale that already
exists, so an existing one is PATCHed instead. That makes this safe to re-run.
"""
import pathlib, re, sys
from asc import call
from aso import ASO
from legal import footer

APP_ID = "6803566012"
LISTING = pathlib.Path.home() / "Desktop/BrassPawn/listing"
SUPPORT_URL = "https://brasspawn.com/support"
MARKETING_URL = "https://brasspawn.com"
PRIVACY_URL = "https://brasspawn.com/privacy"


def sections(locale):
    """Pull the description and the promotional text out of one markdown file."""
    text = (LISTING / f"{locale}.md").read_text()
    out = {}
    for match in re.finditer(r"^## ([A-Za-z ]+?)(?: \(\d+/\d+\))?\s*$", text, re.M):
        name = match.group(1).strip().lower()
        start = match.end()
        nxt = re.search(r"^## ", text[start:], re.M)
        body = text[start:start + nxt.start()] if nxt else text[start:]
        out[name] = body.strip()
    return out


def find(collection, parent, locale):
    for item in call("GET", f"/{parent}/{collection}?limit=200").get("data", []):
        if item["attributes"]["locale"] == locale:
            return item["id"]
    return None


def upsert(kind, parent_type, parent_id, existing, locale, attrs):
    if existing:
        call("PATCH", f"/{kind}/{existing}",
             {"data": {"type": kind, "id": existing, "attributes": attrs}})
        return "updated"
    call("POST", f"/{kind}", {"data": {
        "type": kind,
        "attributes": dict(attrs, locale=locale),
        "relationships": {parent_type[0]: {"data": {"type": parent_type[1], "id": parent_id}}},
    }})
    return "created"


def main():
    app_info = call("GET", f"/apps/{APP_ID}/appInfos")["data"][0]["id"]
    version = next(v for v in call("GET", f"/apps/{APP_ID}/appStoreVersions")["data"]
                   if v["attributes"]["platform"] == "IOS")["id"]

    info_seen = {i["attributes"]["locale"]: i["id"] for i in
                 call("GET", f"/appInfos/{app_info}/appInfoLocalizations?limit=200")["data"]}
    ver_seen = {i["attributes"]["locale"]: i["id"] for i in
                call("GET", f"/appStoreVersions/{version}/appStoreVersionLocalizations?limit=200")["data"]}

    only = sys.argv[1:] or sorted(ASO)
    for locale in only:
        name, subtitle, keywords = ASO[locale]
        s = sections(locale)
        # Guideline 3.1.2 wants the subscription terms and both legal links in
        # the metadata, not only on the purchase screen. Appended rather than
        # written into the source files so the prose stays prose.
        description = (s.get("description", "").rstrip() + "\n\n" + footer(locale))
        promo = s.get("promotional text", "")
        if len(description) > 4000:
            raise SystemExit(f"{locale}: description is {len(description)} characters")

        a = upsert("appInfoLocalizations", ("appInfo", "appInfos"), app_info,
                   info_seen.get(locale), locale,
                   {"name": name, "subtitle": subtitle, "privacyPolicyUrl": PRIVACY_URL})

        # Creating the app-info localization makes Apple create the version's
        # localization for that locale too, so anything read before this point
        # is already out of date. Ask again rather than POST into a 409.
        if a == "created":
            ver_seen = {i["attributes"]["locale"]: i["id"] for i in
                        call("GET", f"/appStoreVersions/{version}"
                                    "/appStoreVersionLocalizations?limit=200")["data"]}

        b = upsert("appStoreVersionLocalizations",
                   ("appStoreVersion", "appStoreVersions"), version,
                   ver_seen.get(locale), locale,
                   {"description": description, "keywords": keywords,
                    "promotionalText": promo,
                    "supportUrl": SUPPORT_URL, "marketingUrl": MARKETING_URL})

        print(f"{locale:8} info {a:7} version {b:7}  {name}  |  {subtitle}")


if __name__ == "__main__":
    main()
