// Who is about right now: the one thing Game Center cannot say.
//
// While the app is on screen, and the player has not turned "Show when I'm
// online" off, it says so every few minutes — here, looking for a game on a
// clock, or in one — and says goodbye when it goes to the background. Each
// word lasts five minutes and then expires on its own (DynamoDB's TTL, and
// the filter below, which does not wait for it), so a phone that died, or a
// window left open behind others, drops off the list rather than staying on
// it all night. Nothing is kept past that: no history, no log of who was on.
//
// The table is anything with put/remove/scan (dynamo.mjs, or a Map in the
// tests); a player is their hashed key, never their Game Center ID.

export const TABLE = process.env.PRESENCE_TABLE ?? 'brasspawn-presence';
/** How long one "here" lasts. The app says it again every three minutes. */
export const LASTS_S = 5 * 60;
const STATUSES = new Set(['online', 'looking', 'playing']);
const CLOCKS = new Set([3, 5, 10, 15, 30]);

export function openPresence({ db, table = TABLE, now = () => Date.now() }) {
  return {
    /** This player is here, and doing this. */
    async here(player, { status, minutes } = {}) {
      if (!STATUSES.has(status)) throw new Error('no status');
      const clock = status === 'online' ? null : CLOCKS.has(minutes) ? minutes : null;
      if (status !== 'online' && clock === null) throw new Error('no such clock');
      const until = Math.floor(now() / 1000) + LASTS_S;
      await db.put(table, {
        player: { S: player },
        status: { S: status },
        ...(clock ? { minutes: { N: String(clock) } } : {}),
        until: { N: String(until) },
      });
      return { status: 'here', until };
    },

    /** This player has gone. */
    async gone(player) {
      await db.remove(table, { player: { S: player } });
      return { status: 'gone' };
    },

    /** Everybody here now. */
    async online() {
      const items = await db.scan(table, {
        FilterExpression: '#until > :now',
        ExpressionAttributeNames: { '#until': 'until' },
        ExpressionAttributeValues: { ':now': { N: String(Math.floor(now() / 1000)) } },
      });
      return {
        players: items.map((item) => ({
          id: item.player.S,
          status: item.status.S,
          ...(item.minutes ? { minutes: Number(item.minutes.N) } : {}),
        })),
      };
    },
  };
}

/** The same table, in memory, for the tests. */
export function memoryTable() {
  const rows = new Map();
  return {
    rows,
    async put(_table, item) {
      rows.set(item.player.S, structuredClone(item));
    },
    async remove(_table, key) {
      rows.delete(key.player.S);
    },
    async scan(_table, { ExpressionAttributeValues }) {
      const at = Number(ExpressionAttributeValues[':now'].N);
      return [...rows.values()].filter((item) => Number(item.until.N) > at).map((item) => structuredClone(item));
    },
  };
}
