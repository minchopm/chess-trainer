# Privacy Policy

**Brass Pawn** collects nothing — apart from saying, while you play online, that
you are online, described under *Who is online* below.

The app makes no analytics calls, carries no advertising, and contains no
third-party tracking of any kind. There is no account to create, and outside
online play nothing about you is ever sent to us.

## What stays on your device

Your training ratings, solved puzzles, review schedule, streaks, game history
and purchase state are stored in the app's own container on your device. Deleting
the app deletes them. They are included in an encrypted device backup only if
you have one; nothing is uploaded anywhere else.

## Game Center

Online play uses Apple's Game Center to find an opponent and to carry the moves
between the two devices. In a match your Game Center nickname and your in-app
online rating are visible to your opponent, because that is what a game between
two people needs. Apple's handling of Game Center data is covered by Apple's own
privacy policy; we receive none of it.

Moves and clocks travel directly between the two devices through Game Center
while you play.

Your online rating lives on Game Center's leaderboards — one for each clock. At
the end of a rated game each player's device works out its own player's new
rating, from both players' ratings as Game Center held them when the game
began, and writes it there, with how sure the rating is, how many rated games
it has and the day of the last one. The app sends it again, unchanged, when you
open it signed in to Game Center. Other players see your Game Center nickname
and when you were last seen there, as your Game Center privacy settings allow;
that is how the app's rank list shows who each player is, how its lists of
active and inactive players are made, and what lets another player invite you
to a game. The leaderboards are Apple's.

## Who is online

Game Center can say who played this week, but not who has the app open now. So
the app tells a small service of ours — a function on Amazon Web Services, in
Frankfurt — when you are there.

While the app is on your screen and you are signed in to Game Center, it tells
the service that you are here — online, looking for a game on a
clock, or in one — again every three minutes, and that you have gone when it
leaves the screen. Other signed-in players see it beside your nickname in the
list of players, so an invitation reaches somebody who is there to play. Each
such note lasts five minutes and is then deleted: nothing is kept about when you
were online. *Settings → Show when I'm online* turns it off.

Each note carries your Game Center team player ID — Apple's identifier for you
in our apps, which is not your name, e-mail or Apple Account — with Apple's
signature proving it is yours, and the service keeps it only as a scrambled
code (a one-way hash of it). Your IP address reaches Amazon, as any web
request's does. Nothing else is sent, and nothing is sold, shared or used for
advertising or tracking. The function's logs are deleted after fourteen days.

## Today

The Today screen shows the games from the top chess events. When you open it,
the app downloads `https://brasspawn.com/media/feed/v1/latest.json`, and as you
scroll back through earlier days, one file for each of them from the same place.
They are the same files for everybody. Nothing is downloaded at launch, in the
background, or at any other time. The App Clip, opened from a story's link on
the site, downloads that one story's file the same way, and leaves the story's
name — nothing else — where the app, if you install it, will find it and open on it.

The request carries no account, no identifier, no cookie and no information
about you or your device beyond what any web request needs to be answered: your
IP address, which reaches Amazon CloudFront, the service that delivers the site.
We keep no logs of these requests — CloudFront and S3 access logging are off —
and nothing is recorded about who downloaded the file or when. The last copy is
kept on your device so the screen works offline.

The stories in it are written by us from public facts: the moves and results of
official broadcasts, relayed by Lichess, and evaluations by Stockfish.

## Purchases

Subscriptions and the one-off unlock are handled entirely by the App Store. We
never see your payment details; the app only asks the App Store whether a
purchase is active.

## Chess data

The bundled puzzles and games come from the Lichess database, released into the
public domain (CC0), and from positions generated on our own machines. They
contain no personal information: the imported games keep the two players'
ratings and moves, and not their usernames.

## Children

Outside online play the app collects no data at all. Online play is through
Game Center, whose age settings Apple applies; our service keeps only what
*Who is online* describes, for five minutes, and nothing that identifies
anybody. It shows no adverts and links out only to the source repository, this
site and the licence text.

## Contact

Questions about this policy, or a request about your data:
privacy@brasspawn.com. Anything else: support@brasspawn.com. The source is at
https://github.com/minchopm/chess-trainer, where an issue is also read.
