// The referee over HTTPS: a Lambda function URL the app posts to, and an
// hourly EventBridge rule that settles the games one of whose players never
// reported (referee.mjs, `sweep`).
//
//   POST /begin   { identity, gameID, minutes, openPool, gameNumber, color }
//   POST /end     { identity, …the same, moves: [uci], outcome, reason }
//
// `identity` is GameKit's identity signature (identity.mjs); the answer to
// /end is the verdict for this player — rated, with the new rating; unrated
// or void, with why; or pending, while the other player's report is awaited.
// The lists themselves are files the site serves (media/ratings/v1/<m>.json),
// so reading them costs nothing here.
import { playerKey, verifyIdentity } from './identity.mjs';
import { openReferee, report, ticket } from './referee.mjs';
import { openStore } from './store.mjs';

const store = openStore();
const referee = openReferee({ store, log: (line) => console.log(line) });

const reply = (statusCode, body) => ({
  statusCode,
  headers: { 'content-type': 'application/json' },
  body: JSON.stringify(body),
});

export const handler = async (event) => {
  // EventBridge: the hourly sweep.
  if (event?.source === 'aws.events' || event?.sweep) {
    const settled = await referee.sweep();
    return { settled: settled.length };
  }

  const path = event?.rawPath ?? '';
  if (event?.requestContext?.http?.method !== 'POST') return reply(405, { error: 'POST only' });
  let body;
  try {
    const raw = event.isBase64Encoded ? Buffer.from(event.body ?? '', 'base64').toString('utf8') : event.body ?? '';
    if (raw.length > 64_000) return reply(413, { error: 'too long' });
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
    if (path === '/begin') return reply(200, await referee.begin(player, ticket(body)));
    if (path === '/end') return reply(200, await referee.end(player, report(body)));
    return reply(404, { error: 'no such thing' });
  } catch (error) {
    // A malformed request says so; anything else is ours, and logged.
    if (/^no /.test(error.message)) return reply(400, { error: error.message });
    console.error(error);
    return reply(500, { error: 'the referee failed' });
  }
};
