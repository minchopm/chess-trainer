// The referee's papers in S3 (s3.mjs, signed by hand): the games and the
// ratings under ratings-state/, which only the referee reads, and each clock's
// list under media/ratings/, which the site serves to the app.
import { openS3 } from '../feed/s3.mjs';

export function openStore({ bucket = process.env.RATINGS_BUCKET ?? 'brasspawn-media', region = process.env.RATINGS_REGION ?? 'eu-central-1' } = {}) {
  const s3 = openS3({ bucket, region });
  const json = { contentType: 'application/json; charset=utf-8' };
  return {
    async get(key) {
      const found = await s3.getTagged(key);
      return found ? { body: JSON.parse(found.text), etag: found.etag } : null;
    },
    /** True if written; false if a condition failed. Unconditional writes always are. */
    put(key, value, { ifMatch, ifNoneMatch } = {}) {
      return s3.putIf(key, JSON.stringify(value), { ...json, ifMatch, ifNoneMatch });
    },
    list: (prefix) => s3.list(prefix),
    remove: (key) => s3.remove(key),
    /** A list the app reads: a minute old at most, wherever it is cached. */
    async publish(key, value) {
      await s3.put(key, JSON.stringify(value), { ...json, cacheControl: 'public, max-age=60' });
    },
  };
}

/** The same, in memory, for the tests. */
export function memoryStore() {
  const objects = new Map();
  let version = 0;
  return {
    objects,
    async get(key) {
      const found = objects.get(key);
      return found ? { body: structuredClone(found.body), etag: found.etag } : null;
    },
    async put(key, value, { ifMatch, ifNoneMatch } = {}) {
      const found = objects.get(key);
      if (ifNoneMatch && found) return false;
      if (ifMatch && found?.etag !== ifMatch) return false;
      objects.set(key, { body: structuredClone(value), etag: `"${++version}"` });
      return true;
    },
    async list(prefix) {
      return [...objects.keys()].filter((k) => k.startsWith(prefix)).sort().map((key) => ({ key }));
    },
    async remove(key) {
      objects.delete(key);
    },
    async publish(key, value) {
      objects.set(key, { body: structuredClone(value), etag: `"${++version}"` });
    },
  };
}
