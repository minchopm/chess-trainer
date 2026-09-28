// Friends of our own: a request from one player to another, accepted or not,
// and games offered between friends.
//
// Game Center's friends are made through Messages, to a contact; nothing in it
// lets one player ask another by the nickname on a list. So these are kept
// here, in one table:
//
//   P#<player>  L#<other>   a link: 'out' (asked), 'in' (was asked) or
//                           'friend' — and the other's nickname, as the other
//                           gave it, so the list can show who it is
//   P#<player>  I#<other>   a game offered by the other, on a clock; gone two
//                           minutes later (DynamoDB's TTL, and the filter here)
//
// Each link is written on both sides, so either reads its own list with one
// query. A player is their hashed key, never their Game Center ID; removing a
// friend, declining or cancelling deletes both sides.

export const TABLE = process.env.FRIENDS_TABLE ?? 'brasspawn-friends';
/** How long an offered game waits for an answer. */
export const INVITE_S = 120;
/** Enough for anybody; a stop on somebody asking the whole list. */
export const MOST_PENDING = 100;
export const MOST_FRIENDS = 300;
const CLOCKS = new Set([3, 5, 10, 15, 30]);
const KEY = /^[0-9a-f]{32}$/;

const pk = (player) => ({ S: `P#${player}` });
const link = (other) => ({ S: `L#${other}` });
const invite = (other) => ({ S: `I#${other}` });

/** A nickname as a player gives it: trimmed, short, and plain text. */
export function nickname(value) {
  if (typeof value !== 'string') throw new Error('no nickname');
  const clean = value.replace(/[\u0000-\u001f\u007f]/g, '').trim().slice(0, 40);
  if (!clean) throw new Error('no nickname');
  return clean;
}

function other(value) {
  if (typeof value !== 'string' || !KEY.test(value)) throw new Error('no player');
  return value;
}

export function openFriends({ db, table = TABLE, now = () => Date.now() }) {
  const seconds = () => Math.floor(now() / 1000);

  async function items(player, prefix) {
    return db.query(table, {
      KeyConditionExpression: prefix ? 'pk = :pk AND begins_with(sk, :prefix)' : 'pk = :pk',
      ExpressionAttributeValues: { ':pk': pk(player), ...(prefix ? { ':prefix': { S: prefix } } : {}) },
    });
  }

  async function linkOf(player, to) {
    return (await items(player, `L#${to}`)).find((item) => item.sk.S === `L#${to}`) ?? null;
  }

  async function write(player, to, state, alias, since = now()) {
    await db.put(table, { pk: pk(player), sk: link(to), state: { S: state }, alias: { S: alias }, since: { N: String(since) } });
  }

  async function unlink(a, b) {
    await Promise.all([
      db.remove(table, { pk: pk(a), sk: link(b) }),
      db.remove(table, { pk: pk(b), sk: link(a) }),
      db.remove(table, { pk: pk(a), sk: invite(b) }),
      db.remove(table, { pk: pk(b), sk: invite(a) }),
    ]);
  }

  /** Everything of one player's: friends, requests both ways, and games offered. */
  async function list(player) {
    const out = { friends: [], incoming: [], outgoing: [], invites: [] };
    for (const item of await items(player)) {
      const [kind, id] = [item.sk.S.slice(0, 2), item.sk.S.slice(2)];
      const alias = item.alias?.S ?? '';
      if (kind === 'L#') {
        const state = item.state.S;
        const entry = { id, alias, since: Number(item.since?.N ?? 0) };
        (state === 'friend' ? out.friends : state === 'in' ? out.incoming : out.outgoing).push(entry);
      } else if (kind === 'I#' && Number(item.until.N) > seconds()) {
        out.invites.push({ id, alias, minutes: Number(item.minutes.N) });
      }
    }
    return out;
  }

  return {
    list,

    /** Games offered to this player, and nothing else: cheap enough to ask often. */
    async invites(player) {
      return {
        invites: (await items(player, 'I#'))
          .filter((item) => Number(item.until.N) > seconds())
          .map((item) => ({ id: item.sk.S.slice(2), alias: item.alias?.S ?? '', minutes: Number(item.minutes.N) })),
      };
    },

    /** Ask to be friends — or, if they already asked, say yes. */
    async request(player, { alias, to, toAlias }) {
      const me = nickname(alias);
      const them = other(to);
      const theirName = nickname(toAlias);
      if (them === player) throw new Error('no player: that is you');
      const mine = await linkOf(player, them);
      if (mine?.state.S === 'friend' || mine?.state.S === 'out') return { status: mine.state.S === 'friend' ? 'friends' : 'asked' };
      if (mine?.state.S === 'in') {
        await write(player, them, 'friend', mine.alias.S);
        await write(them, player, 'friend', me);
        return { status: 'friends' };
      }
      const [mineAll, theirsAll] = await Promise.all([items(player, 'L#'), items(them, 'L#')]);
      if (mineAll.filter((i) => i.state.S === 'out').length >= MOST_PENDING) throw new Error('no more requests: too many waiting');
      if (theirsAll.filter((i) => i.state.S === 'in').length >= MOST_PENDING) throw new Error('no more requests: they have too many waiting');
      if (mineAll.filter((i) => i.state.S === 'friend').length >= MOST_FRIENDS) throw new Error('no more friends: the list is full');
      await write(player, them, 'out', theirName);
      await write(them, player, 'in', me);
      return { status: 'asked' };
    },

    /** Say yes to a request. */
    async accept(player, { alias, from }) {
      const me = nickname(alias);
      const them = other(from);
      const mine = await linkOf(player, them);
      if (mine?.state.S === 'friend') return { status: 'friends' };
      if (mine?.state.S !== 'in') throw new Error('no request from them');
      await write(player, them, 'friend', mine.alias.S);
      await write(them, player, 'friend', me);
      return { status: 'friends' };
    },

    /** No longer friends, a request declined, or one taken back: both sides go. */
    async remove(player, { other: them }) {
      await unlink(player, other(them));
      return { status: 'removed' };
    },

    /** Offer a friend a game on a clock. */
    async invite(player, { alias, to, minutes }) {
      const me = nickname(alias);
      const them = other(to);
      if (!CLOCKS.has(minutes)) throw new Error('no such clock');
      if ((await linkOf(player, them))?.state.S !== 'friend') throw new Error('no friend of yours');
      await db.put(table, {
        pk: pk(them), sk: invite(player), alias: { S: me },
        minutes: { N: String(minutes) }, until: { N: String(seconds() + INVITE_S) },
      });
      return { status: 'offered', until: seconds() + INVITE_S };
    },

    /** An offered game answered — yes or no — by the one it was offered to. */
    async answer(player, { from }) {
      await db.remove(table, { pk: pk(player), sk: invite(other(from)) });
      return { status: 'answered' };
    },

    /** An offered game taken back by the one who offered it. */
    async cancel(player, { to }) {
      await db.remove(table, { pk: pk(other(to)), sk: invite(player) });
      return { status: 'cancelled' };
    },
  };
}

/** The same table, in memory, for the tests. */
export function memoryFriends() {
  const rows = new Map();
  const id = (item) => `${item.pk.S}|${item.sk.S}`;
  return {
    rows,
    async put(_table, item) { rows.set(id(item), structuredClone(item)); },
    async remove(_table, key) { rows.delete(id(key)); },
    async query(_table, { ExpressionAttributeValues: v }) {
      return [...rows.values()]
        .filter((item) => item.pk.S === v[':pk'].S && (!v[':prefix'] || item.sk.S.startsWith(v[':prefix'].S)))
        .map((item) => structuredClone(item));
    },
  };
}
