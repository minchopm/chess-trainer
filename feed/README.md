# The daily feed

The finished games from the top broadcasts, each with the move where Stockfish
says it turned. The app shows them on its Today screen (iPhone, iPad and Mac
alike); the site has a list at `brasspawn.com/today` and a page for each story.
All of them read the same files. A new story needs no app release and no site
deploy.

## Where it lives

```
s3://brasspawn-media/media/feed/v1/latest.json        the newest three days, and the list of every day
s3://brasspawn-media/media/feed/v1/days/<date>.json   one day, for going back through the history
s3://brasspawn-media/media/feed/v1/stories/<id>.json  one story
s3://brasspawn-media/feed-state/v1/state.json         what the collector has read — not public
```

Public through `https://brasspawn.com/media/feed/v1/…`, five minutes at the edge.
S3 is spoken to in signed HTTP (`scripts/feed/s3.mjs`), with no SDK.

## How stories get there

**The collector** (`scripts/feed/collect.mjs`) runs in Lambda every two hours
(`brasspawn-feed-collector`, eu-central-1). It reads the top broadcasts on Lichess.
Once all of an event's rounds for a day are over, it picks that day's games:

- five from a top-tier event's open section and two from its women's;
- three from a tier-4 event, and only games with a followed player or someone
  rated 2680 or more.

It analyses each game and writes a story with status `auto`. The words of an
`auto` story say only what the broadcast and the engine say
(`scripts/feed/words.mjs`).

**A person** can rewrite any of them:

```sh
node scripts/feed/pull.mjs 2026-09-25       # the day's stories → feed/drafts/2026-09-25.json
node scripts/feed/lines.mjs 2026-09-25      # what the engine sees at each key moment
#                                             rewrite headline and body; "status": "approved"
node scripts/feed/review.mjs 2026-09-25     # feed/drafts/2026-09-25.html — boards beside words
node scripts/feed/publish.mjs               # check every approved draft; writes nothing
node scripts/feed/publish.mjs --upload      # write them over the collector's version
```

Which statuses the public files carry is the Lambda's `FEED_PUBLIC`: `all` while
the feature is tested, `approved` for only rewritten stories. It is the one switch
for the app and the site alike: both show exactly what the public files carry.

## Running and changing it

```sh
scripts/feed/deploy-lambda.sh                                         # create or update the Lambda and its schedule
node scripts/feed/collect.mjs --hours 720 --pages 5 --workers 4       # a month back, by hand
node scripts/feed/collect.mjs --dry-run                               # read and analyse, write nothing
node scripts/feed/reshape.mjs                                         # rewrite every story in today's shape
node scripts/feed/site.mjs [--empty]                                  # the site's copy (run before every build)
node scripts/feed/pages.mjs [--dry-run]                               # every public story given its page; the lists rewritten
aws lambda invoke --region eu-central-1 --function-name brasspawn-feed-collector \
  --payload '{"renderCheck":"<story id>"}' --cli-binary-format raw-in-base64-out /dev/stdout   # the renderer, tried in Lambda
aws logs tail /aws/lambda/brasspawn-feed-collector --region eu-central-1 --follow
```

## A page for every story, as it is written

`web/scripts/deploy.sh` runs `site.mjs` before every build, so a deploy prerenders
the history as it stands. A story newer than that gets its page from the
collector, the moment it writes the story (`pages.mjs`): rendered with the site's
own renderer — the Angular server bundle of the deployed build
(`web/src/server.ts`), which the Lambda's package carries and every site deploy
refreshes — and written to the site's bucket at `today/<id>/index.html`. The
page is the one a deploy would have made, and the next deploy writes it again.

Every run also rewrites `sitemap-today.xml` (the stories' half of the sitemap,
which `sitemap.xml` indexes beside the deploy's `sitemap-pages.xml`) and the
Atom feed at `today/feed.xml`, and tells IndexNow about the new pages. A story's
`url` in the feed is its page once it has one; a page that failed to render is
tried again on the next run. Approving a story (`publish.mjs --upload`) renders
its page again in the approved words — with the local build, so deploy the site
first if it has changed. Nothing here needs CI or a server: the Lambda that
collects the stories writes their pages.

## Getting from the site into the app

Every story page offers the game in Brass Pawn, differently by device:

- **iPhone and iPad**: *Open this game in Brass Pawn* goes to the App Clip link
  `https://appclip.apple.com/id?p=com.arte-soft.brasspawn.Clip&s=<id>`, the same
  form a game invitation uses. If the app is installed, iOS opens the app on the
  story. If it isn't, the clip opens on the story: the board, the moves, and
  *Get Brass Pawn*. It also writes the story's id to the App Group, so the app
  installed from it opens on that game at first launch (`SharedContainer.takeStory()`).
- **A Mac or anything else**: the App Store, and *Already have it? Open this
  game* (`brasspawn://today/<id>`, which the Mac app answers too).
- Safari's banner carries `app-argument=brasspawn://today/<id>` for anyone who
  has the app.

The home page shows the three weightiest stories of the latest day, prerendered
from the last deploy and refreshed from the live feed in the browser.

## What a story may say

- **Facts from the broadcast**: who played, the result, the moves, the event and
  round, the ratings and teams in the game's tags, the clock after a move.
- **The engine's view, called that**: "the engine's assessment went from a clear
  advantage for White to a winning one", "the engine preferred 40...Rh3+".
- **Nothing else about the people.** No quotes, no feelings, plans, form, nerves or
  intentions, and no "he" or "she": the feed uses names instead, and `publish.mjs`
  refuses a story with a gendered pronoun in it. If the relay does not say a
  game ended in resignation, the story does not say it either.
- **No photographs of anybody.** The boards are drawn by Brass Pawn.

`players.json` lists the players the feed looks for first, matched on FIDE ID. It
also corrects names that are written surname first, such as Ding Liren.
