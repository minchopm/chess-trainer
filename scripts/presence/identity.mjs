// Who is asking: Game Center's own word for it.
//
// The app asks GameKit for an identity signature
// (`fetchItems(forIdentityVerificationSignature:)`) and sends it with every
// request. Apple signs the player's team-scoped ID, the app's bundle ID, a
// timestamp and a salt with a key whose certificate it publishes on an
// apple.com address; checking that signature here is what makes a report
// this player's and nobody else's. It proves who is speaking, not what they
// say: that is the referee's business (referee.mjs).
import { X509Certificate, createHash, verify } from 'node:crypto';

export const BUNDLE_IDS = new Set(['com.arte-soft.brasspawn']);
/** A signature older than this is not taken: it could be a replay. */
const MAX_AGE_MS = 15 * 60_000;
const certificates = new Map();

/** The player's ID as the referee keeps it: never the ID itself. */
export function playerKey(teamPlayerID) {
  return createHash('sha256').update(`brasspawn:${teamPlayerID}`).digest('hex').slice(0, 32);
}

async function certificate(url) {
  const cached = certificates.get(url);
  if (cached) return cached;
  const response = await fetch(url);
  if (!response.ok) throw new Error(`certificate ${response.status}`);
  const cert = new X509Certificate(Buffer.from(await response.arrayBuffer()));
  certificates.set(url, cert);
  return cert;
}

/**
 * The team player ID the signature vouches for, or an error saying why not.
 * `fetchCertificate` is there for the tests, which sign with their own key.
 */
export async function verifyIdentity(identity, { now = Date.now(), fetchCertificate = certificate } = {}) {
  const { playerID, bundleID, publicKeyURL, signature, salt, timestamp } = identity ?? {};
  if (typeof playerID !== 'string' || !playerID || playerID.length > 128) throw new Error('no player');
  if (!BUNDLE_IDS.has(bundleID)) throw new Error('not this app');
  let url;
  try {
    url = new URL(publicKeyURL);
  } catch {
    throw new Error('no key address');
  }
  // Apple's key, from Apple: anything else could have been signed by anyone.
  if (url.protocol !== 'https:' || !(url.hostname === 'apple.com' || url.hostname.endsWith('.apple.com'))) {
    throw new Error('key not from apple.com');
  }
  const stamp = Number(timestamp);
  if (!Number.isSafeInteger(stamp) || Math.abs(now - stamp) > MAX_AGE_MS) throw new Error('stale signature');

  const cert = await fetchCertificate(url.href);
  if (now < Date.parse(cert.validFrom) || now > Date.parse(cert.validTo)) throw new Error('certificate expired');
  const time = Buffer.alloc(8);
  time.writeBigUInt64BE(BigInt(stamp));
  const signed = Buffer.concat([Buffer.from(playerID, 'utf8'), Buffer.from(bundleID, 'utf8'), time, Buffer.from(salt ?? '', 'base64')]);
  if (!verify('sha256', signed, cert.publicKey, Buffer.from(signature ?? '', 'base64'))) throw new Error('bad signature');
  return playerID;
}
