# The store listing, in thirty-one languages

`upload.py` writes the App Store listing for every locale through the App Store
Connect API. It is create-or-update throughout, so it is safe to run again.

```bash
export ASC_ISSUER_ID=...          # Users and Access -> Integrations
export ASC_KEY_ID=...             # the key's ID, e.g. ABCD123456
export ASC_KEY_PATH=~/keys/AuthKey_ABCD123456.p8
python3 upload.py                 # every locale
python3 upload.py de-DE ja        # or just these
```

Needs `PyJWT` and `cryptography`.

## Where each field lives

Apple splits the listing across two objects, and it matters which is which:

| | Object | Survives a new version? |
|---|---|---|
| Name, subtitle, privacy policy URL | `appInfoLocalizations` | yes |
| Description, keywords, promotional text, support and marketing URLs | `appStoreVersionLocalizations` | no |

Creating an app-info localization for a new locale makes Apple create the
version localization for it as well. Anything read before that point is stale,
which is why the script re-reads rather than POSTing into a 409.

## Why the copy is shaped the way it is

**Apple searches the app name, the subtitle and the keyword field. It does not
search the description.** That single fact decides everything here:

- The name and subtitle are the only places a search term earns its keep, so
  both carry real words rather than a slogan. The name is
  `Brass Pawn: <chess trainer>` in each language — the brand first, because it
  has to read as a name, then the two words somebody would actually type.
- Apple indexes the *union* of the three fields, so a word already in the name
  or the subtitle is a wasted character if it is repeated in the keywords. The
  keyword field is spent entirely on words the other two do not carry. The
  check at the bottom of `aso.py` enforces this.
- Where a language would ordinarily compound "chess" and "trainer" — German,
  Dutch, the Nordics — the two words are written apart so both tokens index.
- The description is free to be well written, because no ranking depends on it.
  It comes from `~/Desktop/BrassPawn/listing/<locale>.md`, which is also where
  the promotional text comes from.

## The block at the foot of every description

Guideline 3.1.2 wants four things in the *metadata* of an app with an
auto-renewable subscription: what the subscription is, how long it runs, what
it costs, and working links to the Terms of Use and the privacy policy. Having
them on the purchase screen — which this app always did — is not enough. A
listing without them is returned, every time.

`legal.py` holds that block in all thirty-one languages and `upload.py` appends
it to the description. Kept apart from the prose so the description stays
readable and the legal text stays in one place.

Two decisions worth recording:

- **No price is written into it.** It would have to be right in a hundred and
  seventy-five storefronts, it changes without the listing changing, and the
  purchase screen shows it in the reader's own currency. The other live apps on
  this account are approved without it.
- **The EULA is Apple's standard one**, `apple.com/legal/…/stdeula/`, which is
  what every other app on the account uses. No custom agreement is registered,
  so nothing has to be maintained.

## The rest

`stockfish` is in every keyword list. It is a search term with real volume and
it is not a competitor's name being borrowed: the engine is in the app.
