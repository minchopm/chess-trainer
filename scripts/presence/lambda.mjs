// Who is online, over HTTPS: a Lambda function URL the app posts to.
//
//   POST /here    { identity, status: online|looking|playing, minutes? } — on screen now
//   POST /gone    { identity } — gone to the background, or hidden
//   POST /online  { identity } — who is here now
//
//   POST /friends          { identity } — friends, requests both ways, games offered
//   POST /friends/invites  { identity } — just the games offered, to ask often
//   POST /friends/request  { identity, alias, to, toAlias }
//   POST /friends/accept   { identity, alias, from }
//   POST /friends/remove   { identity, other } — unfriend, decline or take back
//   POST /friends/invite   { identity, alias, to, minutes } — offer a friend a game
//   POST /friends/answer   { identity, from } — an offered game, answered
//   POST /friends/cancel   { identity, to } — an offered game, taken back
//
// `identity` is GameKit's identity signature (identity.mjs), so only players
// of this app, signed in to Game Center, can say they are here or ask who is.
// Ratings are not here: each device works them out at the end of a game and
// writes them to Game Center (ios/Sources/ChessTraining/OnlineRecord.swift).
// Friends are (friends.mjs): Game Center's cannot be asked for by nickname.
import { openDynamo } from './dynamo.mjs';
import { playerKey, verifyIdentity } from './identity.mjs';
import { openFriends } from './friends.mjs';
import { openPresence } from './presence.mjs';

const db = openDynamo({ region: process.env.PRESENCE_REGION ?? 'eu-central-1' });
const presence = openPresence({ db });
const friends = openFriends({ db });

const reply = (statusCode, body) => ({
  statusCode,
  headers: { 'content-type': 'application/json' },
  body: JSON.stringify(body),
});

export const handler = async (event) => {
  // The deploy's check that the table can be written, read and cleared.
  if (event?.presenceCheck) {
    const probe = '0'.repeat(32);
    await presence.here(probe, { status: 'online' });
    const seen = (await presence.online()).players.some((p) => p.id === probe);
    await presence.gone(probe);
    // And the friends table: a request between two probes, seen, and taken back.
    const other = '1'.repeat(32);
    await friends.request(probe, { alias: 'probe', to: other, toAlias: 'probe' });
    const asked = (await friends.list(other)).incoming.some((f) => f.id === probe);
    await friends.remove(probe, { other });
    const unasked = (await friends.list(other)).incoming.length === 0;
    return { seen, cleared: !(await presence.online()).players.some((p) => p.id === probe), asked, unasked };
  }

  const path = event?.rawPath ?? '';
  if (event?.requestContext?.http?.method !== 'POST') return reply(405, { error: 'POST only' });
  let body;
  try {
    const raw = event.isBase64Encoded ? Buffer.from(event.body ?? '', 'base64').toString('utf8') : event.body ?? '';
    if (raw.length > 8_000) return reply(413, { error: 'too long' });
    body = JSON.parse(raw);
  } catch {
    return reply(400, { error: 'not JSON' });
  }

  let player;
  try {
    player = playerKey(await verifyIdentity(body.identity));
  } catch (error) {
    return reply(401, { error: `identity: ${error.message}` });
  }

  try {
    // Saying "here" also hears whether a friend has offered a game.
    if (path === '/here') return reply(200, { ...(await presence.here(player, body)), ...(await friends.invites(player)) });
    if (path === '/gone') return reply(200, await presence.gone(player));
    if (path === '/online') return reply(200, await presence.online());
    if (path === '/friends') return reply(200, await friends.list(player));
    if (path === '/friends/invites') return reply(200, await friends.invites(player));
    if (path === '/friends/request') return reply(200, await friends.request(player, body));
    if (path === '/friends/accept') return reply(200, await friends.accept(player, body));
    if (path === '/friends/remove') return reply(200, await friends.remove(player, body));
    if (path === '/friends/invite') return reply(200, await friends.invite(player, body));
    if (path === '/friends/answer') return reply(200, await friends.answer(player, body));
    if (path === '/friends/cancel') return reply(200, await friends.cancel(player, body));
    return reply(404, { error: 'no such thing' });
  } catch (error) {
    // A malformed request says so; anything else is ours, and logged.
    if (/^no /.test(error.message)) return reply(400, { error: error.message });
    console.error(error);
    return reply(500, { error: 'presence failed' });
  }
};
