// node --test scripts/presence/test.mjs
import assert from 'node:assert/strict';
import { generateKeyPairSync, sign } from 'node:crypto';
import { test } from 'node:test';

import { playerKey, verifyIdentity } from './identity.mjs';
import { INVITE_S, memoryFriends, openFriends } from './friends.mjs';
import { LASTS_S, memoryTable, openPresence } from './presence.mjs';

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

const ANN = playerKey('T:_ann');
const BO = playerKey('T:_bo');
const CY = playerKey('T:_cy');

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

// ---------------------------------------------------------------- friends

function friendsSetup() {
  let clock = Date.UTC(2026, 8, 28, 12);
  const db = memoryFriends();
  return { db, friends: openFriends({ db, now: () => clock }), later: (ms) => (clock += ms) };
}

test('friends: asked, accepted, listed on both sides', async () => {
  const { friends } = friendsSetup();
  assert.deepEqual(await friends.request(ANN, { alias: 'Ann', to: BO, toAlias: 'Bo' }), { status: 'asked' });
  assert.deepEqual((await friends.list(ANN)).outgoing.map((f) => [f.id, f.alias]), [[BO, 'Bo']]);
  assert.deepEqual((await friends.list(BO)).incoming.map((f) => [f.id, f.alias]), [[ANN, 'Ann']]);
  assert.deepEqual(await friends.accept(BO, { alias: 'Bo', from: ANN }), { status: 'friends' });
  assert.deepEqual((await friends.list(ANN)).friends.map((f) => f.alias), ['Bo']);
  assert.deepEqual((await friends.list(BO)).friends.map((f) => f.alias), ['Ann']);
  assert.equal((await friends.list(ANN)).outgoing.length, 0);
});

test('friends: asking somebody who already asked is a yes', async () => {
  const { friends } = friendsSetup();
  await friends.request(ANN, { alias: 'Ann', to: BO, toAlias: 'Bo' });
  assert.deepEqual(await friends.request(BO, { alias: 'Bo', to: ANN, toAlias: 'Ann' }), { status: 'friends' });
  assert.equal((await friends.list(ANN)).friends.length, 1);
});

test('friends: removed, declined or taken back, from both sides', async () => {
  const { friends, db } = friendsSetup();
  await friends.request(ANN, { alias: 'Ann', to: BO, toAlias: 'Bo' });
  await friends.remove(BO, { other: ANN }); // declined
  assert.equal(db.rows.size, 0);
  await friends.request(ANN, { alias: 'Ann', to: BO, toAlias: 'Bo' });
  await friends.accept(BO, { alias: 'Bo', from: ANN });
  await friends.remove(ANN, { other: BO }); // unfriended
  assert.equal(db.rows.size, 0);
  await assert.rejects(friends.accept(BO, { alias: 'Bo', from: ANN }), /no request/);
});

test('friends: a game offered to a friend, answered, or gone in two minutes', async () => {
  const { friends, later } = friendsSetup();
  await assert.rejects(friends.invite(ANN, { alias: 'Ann', to: BO, minutes: 5 }), /no friend/);
  await friends.request(ANN, { alias: 'Ann', to: BO, toAlias: 'Bo' });
  await friends.accept(BO, { alias: 'Bo', from: ANN });
  await friends.invite(ANN, { alias: 'Ann', to: BO, minutes: 5 });
  assert.deepEqual((await friends.invites(BO)).invites, [{ id: ANN, alias: 'Ann', minutes: 5 }]);
  await friends.answer(BO, { from: ANN });
  assert.deepEqual((await friends.invites(BO)).invites, []);
  await friends.invite(ANN, { alias: 'Ann', to: BO, minutes: 10 });
  later((INVITE_S + 1) * 1000);
  assert.deepEqual((await friends.invites(BO)).invites, [], 'gone');
  await friends.invite(ANN, { alias: 'Ann', to: BO, minutes: 3 });
  await friends.cancel(ANN, { to: BO });
  assert.deepEqual((await friends.list(BO)).invites, [], 'taken back');
  await assert.rejects(friends.invite(ANN, { alias: 'Ann', to: BO, minutes: 7 }), /no such clock/);
});

test('friends: nobody is their own friend, and nicknames are plain', async () => {
  const { friends } = friendsSetup();
  await assert.rejects(friends.request(ANN, { alias: 'Ann', to: ANN, toAlias: 'Ann' }), /that is you/);
  await assert.rejects(friends.request(ANN, { alias: 'Ann', to: 'not-a-key', toAlias: 'Bo' }), /no player/);
  await assert.rejects(friends.request(ANN, { alias: '   ', to: BO, toAlias: 'Bo' }), /no nickname/);
  await friends.request(ANN, { alias: 'Ann\u0007' + 'x'.repeat(60), to: BO, toAlias: 'Bo' });
  const [asker] = (await friends.list(BO)).incoming;
  assert.equal(asker.alias, 'Ann' + 'x'.repeat(37));
});
