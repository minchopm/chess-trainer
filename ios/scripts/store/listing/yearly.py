#!/usr/bin/env python3
"""Create the yearly Pro plan in App Store Connect, beside the monthly one.

    python3 yearly.py            create what is missing, and say what is there

Everything the monthly plan has, the yearly one gets the same way: the group,
the level (the same access, so the same level — switching between the two is a
crossgrade), a name and a description in each of the monthly plan's languages,
a price in every territory the monthly plan is sold in, and the same
availability. Safe to run again: each step looks before it writes.

The price is set once, in dollars, and every other territory gets Apple's
equalised price for it — what the monthly plan did, and what keeps the price the
same after tax everywhere without a hundred and seventy-five decisions.

What it does not do: the review screenshot (`screenshot.py`), and submitting —
a new subscription goes in with the next app version, added on its page in App
Store Connect (see README: the API accepts only the version).
"""
import json
import pathlib
import sys

from asc import call

GROUP = "22324080"          # brasspawn.pro
MONTHLY = "6803789121"      # com.artesoft.brasspawn.pro.monthly
PRODUCT = "com.artesoft.brasspawn.pro.yearly"
NAME = "Brass Pawn Pro Yearly"
USD = "19.99"
REVIEW_NOTE = (
    "The yearly plan of Brass Pawn Pro. It gives exactly what the monthly plan and the one-off unlock give: "
    "no daily limits on the Tactics, Rush, positional, endgame and Guess the Elo training, and playing on "
    "against the engine from Today stories older than a day (the last day's stories are free for everyone). "
    "It is offered on the purchase screen: the card icon at the top of the menu, Settings › Brass Pawn Pro, "
    "the foot of Today, or when a day's free training runs out."
)

CATALOG = pathlib.Path(__file__).resolve().parents[3] / "App" / "Localizable.xcstrings"


def every(path):
    """Every page of a listing."""
    out, url = [], path
    while url:
        page = call("GET", url)
        out += page["data"]
        url = page.get("links", {}).get("next")
    return out


def yearly_words():
    strings = json.loads(CATALOG.read_text())["strings"]
    return {l: v["stringUnit"]["value"] for l, v in strings["store.yearly"]["localizations"].items()}


def main():
    subs = every(f"/subscriptionGroups/{GROUP}/subscriptions")
    found = next((s for s in subs if s["attributes"]["productId"] == PRODUCT), None)
    if found:
        sub = found["id"]
        print(f"subscription {sub} exists: {found['attributes']['state']}")
    else:
        made = call("POST", "/subscriptions", {"data": {
            "type": "subscriptions",
            "attributes": {"name": NAME, "productId": PRODUCT, "subscriptionPeriod": "ONE_YEAR",
                           "familySharable": False, "groupLevel": 1, "reviewNote": REVIEW_NOTE},
            "relationships": {"group": {"data": {"type": "subscriptionGroups", "id": GROUP}}},
        }})
        sub = made["data"]["id"]
        print(f"subscription {sub} created")

    # Names and descriptions, in the monthly plan's languages.
    words = yearly_words()
    have = {l["attributes"]["locale"] for l in every(f"/subscriptions/{sub}/subscriptionLocalizations?limit=50")}
    monthly = every(f"/subscriptions/{MONTHLY}/subscriptionLocalizations?limit=50")
    added = 0
    for loc in monthly:
        locale = loc["attributes"]["locale"]
        if locale in have:
            continue
        name = words.get(locale) or words.get(locale.split("-")[0]) or "Yearly"
        call("POST", "/subscriptionLocalizations", {"data": {
            "type": "subscriptionLocalizations",
            "attributes": {"locale": locale, "name": name, "description": loc["attributes"]["description"]},
            "relationships": {"subscription": {"data": {"type": "subscriptions", "id": sub}}},
        }})
        added += 1
    print(f"localizations: {len(have) + added} ({added} added)")

    # Where it is sold: where the monthly plan is.
    try:
        call("GET", f"/subscriptions/{sub}/subscriptionAvailability")
        print("availability: set already")
    except SystemExit:
        monthly_av = call("GET", f"/subscriptions/{MONTHLY}/subscriptionAvailability")["data"]["id"]
        territories = every(f"/subscriptionAvailabilities/{monthly_av}/availableTerritories?limit=200")
        call("POST", "/subscriptionAvailabilities", {"data": {
            "type": "subscriptionAvailabilities",
            "attributes": {"availableInNewTerritories": True},
            "relationships": {
                "subscription": {"data": {"type": "subscriptions", "id": sub}},
                "availableTerritories": {"data": [{"type": "territories", "id": t["id"]} for t in territories]},
            },
        }})
        print(f"availability: {len(territories)} territories")

    # The price: dollars, and Apple's equalised price everywhere else the
    # monthly plan is sold. After the availability: a price for a territory
    # the plan is not yet available in is refused, with nothing more said than
    # "an error occurred while processing the pricing information".
    priced = {p["relationships"]["territory"]["data"]["id"]
              for p in every(f"/subscriptions/{sub}/prices?include=territory&limit=200")}
    points = every(f"/subscriptions/{sub}/pricePoints?filter[territory]=USA&limit=200")
    usa = next(p for p in points if p["attributes"]["customerPrice"] == USD)
    sold = {p["relationships"]["territory"]["data"]["id"]
            for p in every(f"/subscriptions/{MONTHLY}/prices?include=territory&limit=200")}
    equal = every(f"/subscriptionPricePoints/{usa['id']}/equalizations?include=territory&limit=200")
    usa["relationships"]["territory"] = {"data": {"id": "USA"}}
    chosen = [p for p in [usa] + equal
              if p["relationships"]["territory"]["data"]["id"] in sold - priced]
    for point in chosen:
        call("POST", "/subscriptionPrices", {"data": {
            "type": "subscriptionPrices",
            "attributes": {"startDate": None, "preserveCurrentPrice": False},
            "relationships": {
                "subscription": {"data": {"type": "subscriptions", "id": sub}},
                "subscriptionPricePoint": {"data": {"type": "subscriptionPricePoints", "id": point["id"]}},
            },
        }})
    print(f"prices: {len(priced) + len(chosen)} territories ({len(chosen)} added), {USD} USD and its equivalents")

    state = call("GET", f"/subscriptions/{sub}")["data"]["attributes"]["state"]
    print(f"state: {state}")


if __name__ == "__main__":
    sys.exit(main())
