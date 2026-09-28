// Who is online, over HTTPS: a Lambda function URL the app posts to.
//
//   POST /here    { identity, status: online|looking|playing, minutes? } — on screen now
//   POST /gone    { identity } — gone to the background, or hidden
//   POST /online  { identity } — who is here now
//
// `identity` is GameKit's identity signature (identity.mjs), so only players
// of this app, signed in to Game Center, can say they are here or ask who is.
// Ratings are not here: each device works them out at the end of a game and
// writes them to Game Center (ios/Sources/ChessTraining/OnlineRecord.swift).
import { openDynamo } from './dynamo.mjs';
import { playerKey, verifyIdentity } from './identity.mjs';
import { openPresence } from './presence.mjs';

const presence = openPresence({ db: openDynamo({ region: process.env.PRESENCE_REGION ?? 'eu-central-1' }) });

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
    return { seen, cleared: !(await presence.online()).players.some((p) => p.id === probe) };
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
    if (path === '/here') return reply(200, await presence.here(player, body));
    if (path === '/gone') return reply(200, await presence.gone(player));
    if (path === '/online') return reply(200, await presence.online());
    return reply(404, { error: 'no such thing' });
  } catch (error) {
    // A malformed request says so; anything else is ours, and logged.
    if (/^no /.test(error.message)) return reply(400, { error: error.message });
    console.error(error);
    return reply(500, { error: 'presence failed' });
  }
};
