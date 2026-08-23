# App Privacy, answered

The questionnaire in App Store Connect, one screen at a time, with the reason
for each answer. It is a declaration rather than a description: a wrong one is
a problem long after nobody remembers filling it in, so the reasoning is
written down beside the answers.

Apple's definition is the thing to keep hold of throughout. **"Collect" means
transmitting data off the device in a way that lets you or your third-party
partners access it for longer than the immediate request needs.** Data that
stays on the phone is not collected, however personal it is; data that reaches
a server you can read is collected, however dull.

## The first screen

> **Do you or your third-party partners collect any data from this app?**

**No.**

That answer produces the "Data Not Collected" label and ends the
questionnaire. Three things make it the right one:

- **There is no server of ours.** No account, no sign-in, no analytics, no
  advertising, no crash reporting, no third-party SDK of any kind. The app
  makes no HTTP requests at all — there is no `URLSession` in the source.
- **Progress stays in the container.** Ratings, solved puzzles, streaks, game
  history and purchase state are a file on the device. Deleting the app deletes
  them. They reach an encrypted device backup if the owner keeps one, which is
  Apple's backup and not our collection.
- **Both engines are on the phone.** Stockfish and Reckless are compiled in.
  Nothing is sent away to be analysed.

## The two that need thinking about

Neither changes the answer, but both are the kind of thing a reviewer might ask
about, and neither should be discovered for the first time in a rejection.

### Game Center

Online play uses Game Center. In a match the app reads the local player's
`gamePlayerID` and alias, sends them to the opponent, and receives theirs;
moves, clocks and the result travel the same way. The opponent's name is then
written into the local game history, like any other saved game.

This is not collection by us. The transmission is device to device through
Apple's service: **we have no server in the middle and no way to read any of
it.** Apple collects what Apple collects, under Apple's own privacy policy, and
Apple's guidance is explicit that data collected by Apple through its own
frameworks is not the developer's to declare.

Storing the opponent's alias on the device is not collection either, by the
definition above — nothing leaves the phone it is stored on.

### Purchases

The subscription and the one-off unlock go through StoreKit. The App Store
handles payment; the app only asks whether an entitlement is current. No
payment detail is ever visible to the app, and there is nothing to declare:
Apple's transaction data is Apple's.

## The privacy manifest agrees

`ios/App/PrivacyInfo.xcprivacy` declares no tracking, no tracking domains, no
collected data types, and — deliberately — no accessed API types. That last one
is a claim in its own right: the app calls none of the APIs that require a
declared reason. No `UserDefaults`, because progress is a JSON file. No file
timestamps; `attributesOfItem` is used once, to read a network file's size. No
disk space, no boot time, no active keyboard.

**If a future change reaches for one of those, its reason belongs in the
manifest before the change ships.** A manifest that is quietly wrong is worse
than one that is missing.

## Still needed on the same screen

A **Privacy Policy URL** is required, and a file in this repository is not one.
`PRIVACY.md` is written and accurate; it needs somewhere to live that a browser
can reach. GitHub Pages on this repository is the shortest path, and the
address then goes in App Store Connect and never changes.

Nothing else on that screen applies: there is no data to mark as linked to the
user, none used for tracking, and no third-party partners to name.
