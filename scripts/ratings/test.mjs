// node --test scripts/ratings/test.mjs
import assert from 'node:assert/strict';
import { generateKeyPairSync, sign } from 'node:crypto';
import { test } from 'node:test';

import { NEW_DEVIATION, updated } from './glicko.mjs';
import { playerKey, verifyIdentity } from './identity.mjs';
import { LASTS_S, memoryTable, openPresence } from './presence.mjs';
import { CONFIRM_MS, PUBLIC, STATE, openReferee, report } from './referee.mjs';
import { memoryStore } from './store.mjs';

// ---------------------------------------------------------------- Glicko

test('Glicko: the same numbers as the app', () => {
  const first = updated({ rating: 1200, deviation: 350 }, { rating: 1200, deviation: 350 }, 1);
  assert.equal(first.rating, 1362);
  assert.ok(Math.abs(first.deviation - 290.23) < 0.01);
  const settled = (r) => ({ rating: r, deviation: 50 });
  assert.equal(updated(settled(2000), settled(1200), 1).rating, 2000, 'far below: nothing');
  assert.equal(updated(settled(1800), settled(1500), 0.5).rating, 1795, 'a draw with somebody below costs');
  assert.equal(updated(settled(3000), settled(3000), 1).rating, 3007, 'no ceiling');
});

// ---------------------------------------------------------------- identity

const keys = generateKeyPairSync('rsa', { modulusLength: 2048 });
const fakeCertificate = async () => ({ publicKey: keys.publicKey, validFrom: 'Jan 1 00:00:00 2020 GMT', validTo: 'Jan 1 00:00:00 2040 GMT' });

function signed(playerID, { now = Date.now(), bundleID = 'com.arte-soft.brasspawn', url = 'https://static.gc.apple.com/public-key/gc-prod-10.cer' } = {}) {
  const salt = Buffer.from('salty-salt');
  const time = Buffer.alloc(8);
  time.writeBigUInt64BE(BigInt(now));
  const data = Buffer.concat([Buffer.from(playerID), Buffer.from(bundleID), time, salt]);
  return { playerID, bundleID, publicKeyURL: url, timestamp: now, salt: salt.toString('base64'), signature: sign('sha256', data, keys.privateKey).toString('base64') };
}

test('identity: Game Center’s signature, and nothing else', async () => {
  const now = Date.now();
  const check = (identity, at = now) => verifyIdentity(identity, { now: at, fetchCertificate: fakeCertificate });
  assert.equal(await check(signed('T:_abc', { now })), 'T:_abc');
  await assert.rejects(check({ ...signed('T:_abc', { now }), playerID: 'T:_someone-else' }), /bad signature/);
  await assert.rejects(check(signed('T:_abc', { now, bundleID: 'com.example.other' })), /not this app/);
  await assert.rejects(check(signed('T:_abc', { now, url: 'https://evil.example.com/key.cer' })), /apple\.com/);
  await assert.rejects(check(signed('T:_abc', { now, url: 'https://apple.com.evil.example/key.cer' })), /apple\.com/);
  await assert.rejects(check(signed('T:_abc', { now: now - 60 * 60_000 })), /stale/);
  assert.notEqual(playerKey('T:_abc'), playerKey('T:_abd'));
  assert.match(playerKey('T:_abc'), /^[0-9a-f]{32}$/);
});

// ---------------------------------------------------------------- the referee

const ANN = playerKey('T:_ann');
const BO = playerKey('T:_bo');
const CY = playerKey('T:_cy');
// Scholar's mate: White mates on f7.
const MATE = ['e2e4', 'e7e5', 'd1h5', 'b8c6', 'f1c4', 'g8f6', 'h5f7'];
const QUIET = ['e2e4', 'e7e5', 'g1f3', 'b8c6'];

function setup() {
  const store = memoryStore();
  let clock = Date.UTC(2026, 8, 28, 12);
  const referee = openReferee({ store, now: () => clock });
  return { store, referee, later: (ms) => (clock += ms) };
}

const game = (gameID, color, extra = {}) => ({ gameID, minutes: 5, openPool: true, gameNumber: 1, color, ...extra });
const ended = (gameID, color, outcome, reason, moves, extra = {}) =>
  report({ ...game(gameID, color, extra), outcome, reason, moves });

async function play(referee, gameID, white, black, { moves = QUIET, reason = 'resignation', whiteOutcome = 'win', extra = {} } = {}) {
  await referee.begin(white, game(gameID, 'white', extra));
  await referee.begin(black, game(gameID, 'black', extra));
  const loser = { win: 'loss', loss: 'win', draw: 'draw' };
  const first = await referee.end(white, ended(gameID, 'white', whiteOutcome, reason, moves, extra));
  const second = await referee.end(black, ended(gameID, 'black', loser[whiteOutcome], reason, moves, extra));
  return { first, second };
}

test('both agree: rated, with the referee’s own numbers, and listed', async () => {
  const { store, referee } = setup();
  const { first, second } = await play(referee, 'match-0001-1', ANN, BO, { moves: MATE, reason: 'checkmate' });
  assert.equal(first.status, 'pending', 'the first report waits for the second');
  assert.deepEqual(second, { status: 'rated', reason: undefined, minutes: 5, rating: 1038, delta: -162, deviation: second.deviation, games: 1 });
  const again = await referee.end(ANN, ended('match-0001-1', 'white', 'win', 'checkmate', MATE));
  assert.equal(again.status, 'rated');
  assert.equal(again.rating, 1362);
  assert.equal(again.delta, 162);
  const list = store.objects.get(`${PUBLIC}/5.json`).body;
  assert.deepEqual(list.players.map((p) => [p.id, p.rating]), [[ANN, 1362], [BO, 1038]]);
  assert.ok(!store.objects.has(`${STATE}/pending/match-0001-1.json`), 'nothing left pending');
});

test('a changed report after the first is not taken', async () => {
  const { referee } = setup();
  await play(referee, 'match-0002-1', ANN, BO);
  const changed = await referee.end(BO, ended('match-0002-1', 'black', 'win', 'resignation', QUIET));
  assert.equal(changed.status, 'rated');
  assert.equal(changed.delta, -162, 'still the loss that was agreed');
});

test('two reports that disagree rate nothing', async () => {
  const { referee } = setup();
  await referee.begin(ANN, game('match-0003-1', 'white'));
  await referee.begin(BO, game('match-0003-1', 'black'));
  await referee.end(ANN, ended('match-0003-1', 'white', 'win', 'resignation', QUIET));
  const verdict = await referee.end(BO, ended('match-0003-1', 'black', 'win', 'resignation', QUIET));
  assert.deepEqual([verdict.status, verdict.reason], ['void', 'disputed']);
});

test('invitations, rematches and games under two moves are friendlies', async () => {
  const { referee } = setup();
  const invited = await play(referee, 'match-0004-1', ANN, BO, { extra: { openPool: false } });
  assert.deepEqual([invited.second.status, invited.second.reason], ['unrated', 'invitation']);
  const rematch = await play(referee, 'match-0005-2', ANN, CY, { extra: { gameNumber: 2 } });
  assert.deepEqual([rematch.second.status, rematch.second.reason], ['unrated', 'rematch']);
  const aborted = await play(referee, 'match-0006-1', BO, CY, { moves: ['e2e4'] });
  assert.deepEqual([aborted.second.status, aborted.second.reason], ['unrated', 'aborted']);
});

test('one rated game a day against the same opponent, whatever the clock', async () => {
  const { referee, later } = setup();
  assert.equal((await play(referee, 'match-0007-1', ANN, BO)).second.status, 'rated');
  const again = await play(referee, 'match-0008-1', BO, ANN, { extra: { minutes: 10 } });
  assert.deepEqual([again.second.status, again.second.reason], ['unrated', 'sameOpponentToday']);
  assert.equal((await play(referee, 'match-0009-1', ANN, CY)).second.status, 'rated', 'somebody else still counts');
  later(24 * 3600_000);
  assert.equal((await play(referee, 'match-0010-1', ANN, BO)).second.status, 'rated', 'and the next day');
});

test('a lone report: rated once the other has had time to answer', async () => {
  const { referee, later } = setup();
  await referee.begin(ANN, game('match-0011-1', 'white'));
  await referee.begin(BO, game('match-0011-1', 'black'));
  const lone = await referee.end(ANN, ended('match-0011-1', 'white', 'win', 'disconnected', QUIET));
  assert.equal(lone.status, 'pending');
  assert.equal((await referee.sweep()).length, 0, 'too soon');
  later(CONFIRM_MS + 1000);
  const [swept] = await referee.sweep();
  assert.equal(swept.status, 'rated');
  assert.equal((await referee.end(ANN, ended('match-0011-1', 'white', 'win', 'disconnected', QUIET))).rating, 1362);
});

test('a report about a game the other player never began is void', async () => {
  const { referee, later } = setup();
  await referee.begin(ANN, game('match-0012-1', 'white'));
  await referee.end(ANN, ended('match-0012-1', 'white', 'win', 'resignation', QUIET));
  later(CONFIRM_MS + 1000);
  const [swept] = await referee.sweep();
  assert.deepEqual([swept.status, swept.reason], ['void', 'unconfirmed']);
});

test('a game nobody reported is void, once its clocks could have run out', async () => {
  const { referee, later } = setup();
  await referee.begin(ANN, game('match-0013-1', 'white'));
  await referee.begin(BO, game('match-0013-1', 'black'));
  later(30 * 60_000);
  assert.equal((await referee.sweep()).length, 0, 'it could still be being played');
  later(60 * 60_000);
  const [swept] = await referee.sweep();
  assert.deepEqual([swept.status, swept.reason], ['void', 'unreported']);
});

test('moves that do not play, or a mate that is not one, rate nothing', async () => {
  const { referee } = setup();
  const illegal = await play(referee, 'match-0014-1', ANN, BO, { moves: ['e2e5', 'e7e5'] });
  assert.deepEqual([illegal.second.status, illegal.second.reason], ['void', 'illegal']);
  const notMate = await play(referee, 'match-0015-1', ANN, CY, { moves: QUIET, reason: 'checkmate' });
  assert.deepEqual([notMate.second.status, notMate.second.reason], ['void', 'result']);
  // Mated, and claiming the win anyway.
  await referee.begin(BO, game('match-0016-1', 'white'));
  await referee.begin(CY, game('match-0016-1', 'black'));
  await referee.end(BO, ended('match-0016-1', 'white', 'loss', 'checkmate', MATE));
  const wrongWinner = await referee.end(CY, ended('match-0016-1', 'black', 'win', 'checkmate', MATE));
  assert.deepEqual([wrongWinner.status, wrongWinner.reason], ['void', 'result']);
});

test('settled twice at once, counted once', async () => {
  const { store, referee } = setup();
  await referee.begin(ANN, game('match-0017-1', 'white'));
  await referee.begin(BO, game('match-0017-1', 'black'));
  await store.put(`${STATE}/games/match-0017-1/report-${ANN}.json`, { ...ended('match-0017-1', 'white', 'win', 'resignation', QUIET), player: ANN, at: 0 });
  await store.put(`${STATE}/games/match-0017-1/report-${BO}.json`, { ...ended('match-0017-1', 'black', 'loss', 'resignation', QUIET), player: BO, at: 0 });
  const [a, b] = await Promise.all([referee.settle('match-0017-1', { final: false }), referee.settle('match-0017-1', { final: false })]);
  assert.equal(a.status, 'rated');
  assert.deepEqual(a.ratings, b.ratings);
  const state = store.objects.get(`${STATE}/ratings.json`).body;
  assert.equal(state.clocks[5][ANN].games, 1, 'one game, not two');
});

test('a player can have their ratings removed', async () => {
  const { store, referee } = setup();
  await play(referee, 'match-0019-1', ANN, BO);
  assert.deepEqual(await referee.forget(ANN), { status: 'forgotten' });
  const state = store.objects.get(`${STATE}/ratings.json`).body;
  assert.equal(state.clocks[5][ANN], undefined);
  assert.ok(state.clocks[5][BO], 'the opponent keeps theirs');
  assert.deepEqual(Object.keys(state.pairs), [], 'and the pair is forgotten too');
  assert.deepEqual(store.objects.get(`${PUBLIC}/5.json`).body.players.map((p) => p.id), [BO]);
});

test('a new rating is sure of nothing; the referee starts everyone there', async () => {
  const { store, referee } = setup();
  await play(referee, 'match-0018-1', ANN, BO);
  const state = store.objects.get(`${STATE}/ratings.json`).body;
  assert.ok(state.clocks[5][ANN].deviation < NEW_DEVIATION);
});

// ---------------------------------------------------------------- presence

test('presence: here for five minutes, gone when told, and nothing else', async () => {
  let clock = Date.UTC(2026, 8, 28, 12);
  const db = memoryTable();
  const presence = openPresence({ db, now: () => clock });
  await presence.here(ANN, { status: 'online' });
  await presence.here(BO, { status: 'looking', minutes: 5 });
  await presence.here(CY, { status: 'playing', minutes: 10 });
  assert.deepEqual((await presence.online()).players.sort((a, b) => a.id.localeCompare(b.id)),
    [{ id: ANN, status: 'online' }, { id: BO, status: 'looking', minutes: 5 }, { id: CY, status: 'playing', minutes: 10 }]
      .sort((a, b) => a.id.localeCompare(b.id)));
  await presence.gone(BO);
  assert.equal((await presence.online()).players.length, 2);
  clock += (LASTS_S + 1) * 1000;
  assert.deepEqual((await presence.online()).players, [], 'nobody said it again: nobody is here');
  await assert.rejects(presence.here(ANN, { status: 'dancing' }), /no status/);
  await assert.rejects(presence.here(ANN, { status: 'looking', minutes: 7 }), /no such clock/);
  const row = [...db.rows.values()][0] ?? (await presence.here(ANN, { status: 'online' }), [...db.rows.values()][0]);
  assert.deepEqual(Object.keys(row).sort(), ['player', 'status', 'until'], 'nothing kept but who, what and until when');
});
