# Brass Pawn — the website

Lives at `web/` in the app's repository, which is where the site's own Licences
page says it is. `npm` commands below are run from this directory.

The informational site for the Brass Pawn iOS app. Angular 22, prerendered to
static files, with a WebGL title sequence on the front page and the legal pages
the App Store asks for.

It is a brochure, not the app: nothing here plays chess.

```bash
npm start          # → http://localhost:4400
npm run build:prod # → dist/brass-pawn/browser, ready to upload
```

Node 22.22.3 or 24.15 and up — the Angular CLI refuses anything older.

---

## What is in it

| Route       | What it is                                                                             |
| ----------- | -------------------------------------------------------------------------------------- |
| `/`         | The title sequence, the eight modes, the films, the engine, privacy, pricing, questions |
| `/training` | Each mode in full, how a puzzle is mined and verified, and the honest limitations      |
| `/engine`   | Two engines on the device, win-probability grading, and what copyleft costs            |
| `/watch`    | The 900-game library: what got in, what did not, and taking a position over            |
| `/pricing`  | Free versus Pro, the whole allowance, and why it is shaped that way                    |
| `/support`  | How to reach a human, what to send when a puzzle looks wrong, the FAQ                  |
| `/privacy`  | Privacy Policy                                                                         |
| `/terms`    | Terms of Service, including Apple's required minimum terms                             |
| `/licences` | Every third-party component, its licence, and where the source is                      |

Plus one page per language — `/de`, `/ja`, `/ar`, and twenty-seven more — each
with that language's films, that language's screenshots, and that language's
words. See **Thirty-one languages** below.

`/privacy-policy`, `/terms-of-service`, `/eula` and `/licenses` redirect to the
right page, because that is what other people's forms will link to.

Everything is prerendered: `ng build` writes real HTML for every route, so the
legal text is in the file a crawler downloads rather than assembled by a script
it may not run. `tools/postbuild.mjs` then writes `sitemap.xml` and copies the
prerendered 404 to `404.html`, which is where static hosts look for it.

## Thirty-one languages

English is the site root. Every other language is one segment down — `/de`,
`/pt-br`, `/zh-hant` — and each is a real page rather than a machine
translation of the English one.

### Where the words come from

Almost none of them were written for this site, and that is the point. Three
translated corpora already existed:

| Source                              | What it gives                                    |
| ----------------------------------- | ------------------------------------------------ |
| the app's `Localizable.xcstrings`   | 580 keys × 31 languages — the mode names, the privacy claim, the licence notes, the whole pricing sheet |
| `storefront/tools/copy.py`          | seven App Store captions per language, each already matched to the screenshot it sits over |
| `narration/lines.md`                | three spoken lines per language — the best one-sentence description of the product that exists in any of them |

`tools/harvest-copy.py` reads all three and writes `src/app/i18n/copy/<slug>.ts`.
What is left over — about two dozen strings that only a website needs, like
"With narration" and "What it costs" — is written by hand in
`tools/manual.json` and merged in by the same script.

The consequence is worth stating plainly: **a visitor reads the same sentences
here that they will see inside the app**, worded identically, because they are
the same strings. Re-run the script after changing anything in the app:

```bash
python3 tools/harvest-copy.py     # also writes locales.ts and copy.ts
```

`tools/locales.json` is the single source of truth for the language list. The
generator turns it into `src/app/i18n/locales.ts`; `tools/media.py` uses it to
name its output folders; `tools/postbuild.mjs` uses it to build the sitemap's
alternates.

### The films and the screenshots

Six clips and ten stills per language — 372 videos and 620 images, from 5.7 GB
of unedited simulator captures down to about 530 MB:

```bash
python3 tools/media.py                      # everything that is stale
python3 tools/media.py --locales de-DE,ja   # just these
python3 tools/media.py --only shots
```

It reads from `~/Desktop/BrassPawn` by default; set `BRASSPAWN_CAPTURES` to
point elsewhere. Output goes to `media/`, which sits **outside** `public/` on
purpose — half a gigabyte copied into every `ng build` would quadruple a build
that has nothing to do with it.

**It lives in its own bucket**, `brasspawn-media`, attached to the same
CloudFront distribution as a second origin on a `/media/*` cache behaviour. So
a normal deploy never touches it:

```bash
npm run deploy          # the site. Media is not walked, not compared, not touched.
npm run deploy:media    # only after re-running tools/media.py
```

The three ways to host it, and why this one:

| | |
|---|---|
| Same bucket as the site | Works, and every deploy then walks eighteen hundred objects it did not build to conclude it has nothing to do. `PRUNE=1` is one forgotten `--exclude` from deleting all of them. |
| `media.brasspawn.com`, its own distribution | Clean separation, and it puts a DNS lookup and a TLS handshake in front of the first frame of every film, on the connection least able to afford them. Plus a second certificate, and the media becomes cross-origin for no gain. |
| **Its own bucket, same distribution** | URLs stay `/media/...` on the same host, so nothing about the page changes and there is nothing extra to negotiate. Media gets its own bucket, its own cache behaviour and its own lifecycle. |

`scripts/media-behaviour.py` attaches the origin and the behaviour, is
idempotent, and is called by `provision.sh`.

### What it costs

Measured rather than guessed, because "half a gigabyte" sounds expensive and is
not:

| | |
|---|---|
| S3 storage, 532 MB | **$0.012 a month** |
| A normal visit | 2.70 MB — poster, silent loop, seven screenshots |
| The heaviest visit | 6.61 MB — plus the narrated cut and the iPad tab |
| 250,000 visits a month | ~915 GB out, still inside CloudFront's always-free 1 TB |

Storage is not the number that matters; transfer is, and transfer is free until
this site is getting a quarter of a million visits a month. Do not move the
films to a video host to save it. Doing so would put a third-party player — and
its cookies — on a page whose whole argument is that the app sends nothing
anywhere.

Each clip exists twice: a silent cut with no audio track at all, which is what
lets a browser start it unasked, and a narrated cut with a person speaking that
language in the corner. The page opens on the silent one and swaps only when
somebody presses for the narration.

### What is *not* translated

The essays — `/training`, `/tactics`, `/ratings`, `/engine` — and the two legal
pages are English only, and every localised page links to them under a label
that says so. Fifteen thousand words of argument turned into thirty languages
by machine would be thirty pages nobody could vouch for; the localised pages
argue the same case with evidence instead, which is what the films are.

`hreflang` is emitted only on the pages that genuinely exist in every language.
An English-only page claiming a German alternate is how a site teaches a search
engine to distrust the rest of its annotations.

## Findability

Lighthouse, on the deployed site: **SEO 100, accessibility 100, best practices
100**, performance in the low nineties on the home page and ninety on the
content pages. Worth knowing how each of those is held up, because most of it
is invisible from the page.

**Every route is real HTML.** Prerendered at build time, so the legal text and
the glossary are in the file a crawler downloads rather than assembled by a
script it may not run. A CloudFront function maps `/tactics` to the prerendered
`tactics/index.html`; the usual SPA fallback would have served every page as an
empty shell.

**One structured-data graph, not a pile of blocks.** `src/app/core/seo.ts`
emits a single `@graph` in which the publisher, the site and the app are each
stated once and referenced by `@id` from every page, plus a `BreadcrumbList`
per page and, where they belong, `FAQPage` and `DefinedTermSet`. Four
disconnected objects that happen to share a name do not describe an entity a
search engine can reconcile; one graph with resolvable ids does.

**The FAQ appears on exactly one page.** It was on two, which is a duplicate.

**Content that answers questions people actually ask.** `/tactics` and
`/ratings` exist because "what is a fork in chess" and "why is my puzzle rating
higher" are real searches with honest answers this project happens to have. The
motif counts are read out of the bundled library rather than estimated, which
is also why the page is worth linking to.

**Nothing third-party on the critical path.** The typefaces are self-hosted
(`tools/fetch-fonts.mjs`), content-hashed and cached for a year, with the two
faces the title is set in preloaded by name — the script rewrites those
`href`s itself, so hashing them cannot go stale. That removes two DNS lookups
and two TLS handshakes from in front of the first paint, and removes a
disclosure from the privacy policy.

**The scene is built in pieces.** three.js is 617 kB and none of it is needed
to read the title, so it is a dynamic import behind a `type`-only reference,
and `TitleSequence.create()` yields between each phase of construction. Built
in one go it was a single task of several hundred milliseconds; split, the same
work stops blocking interaction. Shaders are compiled up front with
`compileAsync`, and the environment map is a sixteen-pixel gradient rather than
three's `RoomEnvironment` — at the blur it is used at, nothing of the room
survived anyway.

**Security headers.** HSTS, a content policy naming one origin, `nosniff`,
`frame-ancestors 'none'` and a permissions policy, applied by a CloudFront
response-headers policy that `scripts/provision.sh` creates.

**The old address still works.** `chess-trainer.arte-soft.com` answers every
path with a **301** to the same path on `brasspawn.com`, via a CloudFront
function on the old distribution. Permanent rather than temporary, because only
a permanent redirect passes the old address's standing to the new one, and
path-preserving, because a redirect that dumps everything on the front page is
why people believe redirects lose rankings.

### Why 403 and 404 do _not_ go to index.html

The standard Angular hosting recipe answers 403 and 404 with `/index.html` and
a **200**, so the client-side router can take over. It is the right answer for a
single-page app and the wrong one here.

This site is prerendered: `/privacy` is a real file at `privacy/index.html`, and
the CloudFront function maps the one to the other, so every genuine route is
already served as finished HTML. The only requests that reach the error rule are
addresses that do not exist — and answering those with `200 OK` and the home
page is a **soft 404**, which search engines treat as a defect. So they get
`/404.html` with an actual `404`.

## The one thing to change before it goes live

`src/app/core/site.ts` holds everything the pages say about the product — the
domain, the contact address, the App Store link, the prices, the library counts
and the motif glossary. Change it there and it changes everywhere.

The App Store link is still a placeholder. Set **`SITE.appStoreId`** to the real
numeric id once the app is published: it is empty on purpose, and while it is
empty the Safari smart app banner and the `installUrl`/`downloadUrl` in the
structured data stay out of the page entirely rather than pointing at a listing
that does not exist. A broken store link in structured data is worse than none.

The same file has `FILM`, which is the slot for the title film:

```ts
export const FILM = {
  src: null,      // → 'film/brass-pawn.mp4'
  poster: null,   // → 'film/poster.jpg'
  captions: null, // → 'film/brass-pawn.en.vtt'
  ...
};
```

Drop the file into `public/film/`, fill those three in, and the front page
swaps its placeholder frame for a real player that loads only when asked. Until
then the frame says the film is in production, which is true and looks
deliberate.

## The title sequence

**It opens on a poster.** The stage used to sit empty for the second or so it
takes to fetch three.js and build the scene, and an empty stage reads as a
broken site rather than a loading one. `public/poster/` holds frame zero at two
aspects, about 10 kB each in AVIF, rendered from the real scene by
`src/app/pages/poster/poster.ts` — so the canvas fading in over it is a
dissolve between two nearly identical images. Re-export it whenever the scene
changes; the component's own comment says how.

The board is not a still. It plays out three real games — the Opera Game, the
Evergreen and the Immortal — move by move, on a loop, while the camera moves
independently down its own path.

`src/app/three/` is a small three.js scene with no framework in it:

- `pieces.ts` — the six pieces, turned on a lathe rather than downloaded. The
  knight is an extruded silhouette because a lathe cannot make a horse; short
  ears, a blunt muzzle and a heavy cheek are what stop it being a rabbit.
- `board.ts` — the board and the dust, drawn to a canvas so the palette can be
  re-graded from the design tokens.
- `games.ts` — the three move lists, **generated** from PGN by chess.js rather
  than typed out: every move validated, captures resolved to the square the
  taken piece actually stood on, castling split into its two pieces. To add a
  game, expand its PGN the same way rather than writing the plies by hand.
- `board-play.ts` — thirty-two meshes and the animation that moves them.
  Nothing is allocated after construction: a taken piece shrinks away and its
  mesh goes back in the pool, and resetting for the next game puts all
  thirty-two back. Knights hop; everything else lifts and places. Whichever
  piece is moving wears a warmed version of its own colour, and a small light
  travels with it.
- `title-sequence.ts` — the scene, the lights, the pacing of the games, and a
  camera on two Catmull-Rom splines: one for where the lens is, one for what it
  points at. Both are sampled by how far down the hero you have scrolled. It
  measures nothing: size and pixel ratio are passed in, because it has to be
  able to run somewhere with no DOM to ask.
- `title-sequence.worker.ts` — the same scene on a worker thread against an
  OffscreenCanvas. **Off by default**; see `USE_WORKER` in `hero.ts` for what
  was verified, what was not, and why that distinction decides the default.

Three things guard the hero, in order of how much they cost:

1. `core/capability.ts` declines to download the scene at all on data-saver, a
   2G connection, or a device reporting two gigabytes of memory. The poster is
   a real frame, so declining leaves a page that looks finished.
2. The canvas clears to **transparent**, not to the background colour, so a
   scene that fails to present a frame shows the poster rather than a black
   rectangle.
3. The canvas is revealed on the first _painted_ frame, not on the scene being
   built — two genuinely different claims once a worker is involved.

`hero.ts` mounts it and hands it a scroll number. Nothing else in the app knows
it exists, and the page works without it: no WebGL, no JavaScript, or
`prefers-reduced-motion` all produce the same words on the same screen, with
the scene either still or absent.

Quality drops on small screens and on machines with four cores or fewer — no
post-processing, smaller shadow maps, less dust — and the loop stops entirely
whenever the hero is off screen.

## Notes

- **`ng serve` runs with `--hmr=false`** (see `serve.sh`). Angular's template
  hot-reload rebuilds a component's view while keeping the instance, which
  leaves the WebGL renderer drawing into a canvas that is no longer in the
  document. Full reloads are cheap here; a blank hero is not.
- **Fragment links use `[routerLink]="[]" fragment="…"`, never `href="#…"`.**
  A bare fragment resolves against `<base href>` rather than against the
  current URL, so `#who` on the privacy page would jump to the home page. This
  is true even now that the base is `/` — it is not something moving to a
  domain root fixed.
- **Nothing in the header is decided by the page.** The title bar renders
  before the router has resolved anything, in the prerenderer and again in the
  browser. It reads the language out of `location.pathname` (see
  `i18n/current.ts`) rather than being told by the page it sits above — a
  header that hydrates with one set of links and then swaps them does not
  flicker, it ends up with both sets in the document.
- **The reveal-on-scroll directive fails open.** Anything already in view is
  revealed immediately, and a timer reveals the rest after four seconds no
  matter what the observer does. A missed animation is a small loss; an
  invisible page is not.

## Deploying

```bash
npm run deploy
```

Builds, uploads to S3 with the right cache headers, invalidates CloudFront, and
waits until the new HTML is actually being served. Live at
**https://brasspawn.com**.

| Command                     | What it does                                     |
| --------------------------- | ------------------------------------------------ |
| `npm run deploy`            | The whole thing                                  |
| `npm run deploy:dry`        | Prints every AWS call, changes nothing           |
| `npm run deploy:skip-build` | Reuses the existing `dist/`                      |
| `npm run deploy:invalidate` | Just busts the CDN cache                         |
| `PRUNE=1 npm run deploy`    | Also deletes bucket objects no longer in `dist/` |
| `NO_WAIT=1 npm run deploy`  | Returns without waiting for the invalidation     |

Credentials live in `.env` (gitignored; copy `.env.example`). They are the same
AWS keys as the other arte-soft properties — only the bucket and hostname
differ.

Three things the script refuses to do quietly, because each one produces a
deploy that looks like a success and behaves like a no-op:

- **Ship a half-built site.** Fewer than eight prerendered pages is a failed
  build, not a small one, and it stops there.
- **Upload without invalidating.** The CDN would go on serving the old HTML.
- **Disagree with itself about the canonical host.** If `SITE.origin` in
  `src/app/core/site.ts` is not the host being deployed to, it warns — every
  page would ship a canonical tag pointing somewhere else.

### The infrastructure

```bash
npm run provision   # idempotent; run once, or after an accident
```

| Piece      | What                                                                                                                                      |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| S3         | `brasspawn.com`, eu-central-1, **private** — encrypted, all public access blocked                                                         |
| ACM        | `brasspawn.com` + `www.`, in us-east-1 (CloudFront reads certificates from nowhere else)                                                  |
| CloudFront | `E1K81IYSMEAXO9`, OAC to the bucket, HTTP/3, Brotli, redirect-to-https                                                                    |
| Function   | `brasspawn-com-router` — rewrites `/privacy` to `/privacy/index.html`                                                                     |
| Errors     | 403 and 404 both answered by the real `/404.html`, with a 404 status                                                                      |
| Route53    | A and AAAA aliases for both names in the `brasspawn.com` zone; the domain is registered through Route53 with auto-renew and WHOIS privacy |

The function is the part worth understanding. This site is **prerendered**, not
a SPA: `/privacy` is a real HTML file at `privacy/index.html`. A CloudFront S3
_REST_ origin does no index-document resolution, so without the rewrite every
route would miss, fall through to the error page, and lose the prerendered
HTML that the whole point of the build was to produce. The usual SPA trick —
answering 403 with `/index.html` and letting the router sort it out — would
serve every page to a crawler as an empty shell.

Cache headers are set per object at upload, in three passes: hashed bundles are
immutable for a year, images and the sitemap for a day, and HTML is never
cached at all.

## Licence

The site is part of the Brass Pawn project and carries the same licence:
**GNU Affero General Public License v3**. See [LICENSE](../LICENSE) at the root
of the repository.

The exception is stated on the site's own Terms page and is worth repeating
here: the name, the wordmark, the app icon and the artwork and prose written for
this site are not covered by it. The code is.
