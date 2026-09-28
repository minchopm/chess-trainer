# Privacy Policy

**Brass Pawn** collects nothing — apart from what it takes to rate the games you
play online, if you play them, described under *Online ratings* below.

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

The app also puts your online rating on each clock you have played on Game
Center's leaderboards — one for each clock — and sends it again when you open
the app signed in to Game Center. Other players see your Game Center nickname
and when you were last seen there, as your Game Center privacy settings allow;
that is how the app's rank list shows who each player is, how its lists of
active and inactive players are made, and what lets another player invite you
to a game. The leaderboards are Apple's.

## Online ratings

A rating that each device worked out for itself could be made to say anything,
so the ratings of online games are kept by a referee of ours: a small function
on Amazon Web Services, in Frankfurt.

**What the app sends it.** When a game that can be rated begins, and when it
ends, the app sends: your Game Center team player ID — Apple's identifier for
you in our apps, which is not your name, e-mail or Apple Account — with Apple's
signature proving it is yours; the game's ID; the clock; your colour; whether
the game came from the open search, an invitation or a rematch; and, at the
end, the moves and the result. Your IP address reaches Amazon, as any web
request's does. Nothing else — no nickname, no photo, no contacts, no device
details. Friendly games (invitations, rematches) are not sent at all.

**What it keeps.** Your ID only as a scrambled code (a one-way hash of it),
never the ID itself. Beside that code: your rating, how sure it is, how many
rated games you have played, and the day of your last rated game, on each
clock. For a day after a rated game, the pair of codes, so the same two players
are rated once a day. What was sent about each game — the two reports, the
moves, the verdict — is deleted after thirty days. The function's logs, which
name games by their ID and players by their code, are deleted after fourteen
days.

**What it publishes.** Each clock's list — codes, ratings, how sure each is,
the number of games and the day of the last one — at
`https://brasspawn.com/media/ratings/v1/`, which the app reads to show the rank
list. A code says nothing about who you are: the app puts a nickname beside it
only where Game Center shows that player to the person looking.

The referee is used only to rate games. Nothing in it is sold, shared or used
for advertising or tracking. To have your online ratings removed, write to
privacy@brasspawn.com.

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
Game Center, whose age settings Apple applies; the referee keeps only what is
described under *Online ratings*, and nothing that identifies anybody. It shows no adverts and links out only to the source repository, this
site and the licence text.

## Contact

Questions about this policy, or a request about your data:
privacy@brasspawn.com. Anything else: support@brasspawn.com. The source is at
https://github.com/minchopm/chess-trainer, where an issue is also read.
