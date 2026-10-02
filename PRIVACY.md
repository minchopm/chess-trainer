# Privacy Policy

**Brass Pawn** collects nothing — apart from saying, while you play online, that
you are online, and keeping the friends you make in the app, described under
*Who is online* and *Friends* below.

## What the App Store's privacy label means here

Its categories are Apple's, and in Brass Pawn each is narrower than its name:

- **Contacts**: only the friends you add inside Brass Pawn, by their Game
  Center nickname. The app never reads the contacts on your phone.
- **Identifiers (User ID)**: a scrambled code made from your Game Center ID, so
  a friend request or a game reaches the right player. Never your name, e-mail
  address or Apple Account.
- **User Content (Gameplay Content)**: whether you are online, looking for a
  game or in one, deleted five minutes after you leave.

All three come with online friends and "who is online", in version 1.3 and
later. None of it is used for tracking or advertising, and nothing is shared
or sold.

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

If you allow it — Game Center asks the first time you open Friends — the app
reads your Game Center friends, to show the ones who play so that you can ask
them to be friends here too. They are read on the device and sent nowhere; only
a request you choose to send leaves it, as *Friends* describes.

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

## Friends

Game Center makes friends through Messages, with somebody in your contacts, and
has no way to ask a player on a list by nickname. So the app keeps friends of
its own, on the same service.

When you ask somebody to be friends, the service keeps the request under both
players' scrambled codes, with the Game Center nickname each of you had then —
so each list can say who is who — and when it was made. Once it is accepted it
is a friendship, kept the same way. Declining a request, taking it back or
removing a friend deletes it on both sides at once. A game offered to a friend
is kept, with its clock, for two minutes, and deleted as soon as it is answered
or taken back. Only you and the other player see a request or a friendship.

While the app is on your screen and you are signed in to Game Center, it asks
the service for your friends, and — every twenty seconds, if you have any —
whether one of them has offered you a game. Nothing in it is sold, shared or
used for advertising or tracking.

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
*Who is online* and *Friends* describe — who is online, for five minutes, and
the friends you make, until they are removed — as scrambled codes and Game
Center nicknames, never a name, an e-mail address or an Apple Account. It shows no adverts and links out only to the source repository, this
site and the licence text.

## Contact

Questions about this policy, or a request about your data:
privacy@brasspawn.com. Anything else: support@brasspawn.com. The source is at
https://github.com/minchopm/chess-trainer, where an issue is also read.
