// S3 over plain HTTPS, signed by hand — no SDK.
//
// The same SigV4 as MarketBrief's S3DataService.swift, which dropped the SDK
// for the same reason: three calls do not need forty packages, and a Lambda
// that imports none of them starts faster. Virtual-hosted addresses, the
// three signed headers S3 needs, plus the session token that Lambda's
// credentials come with.
import { createHash, createHmac } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';

/**
 * Lambda puts its role's keys in the environment. By hand, the same variables
 * work, and failing them the profile in ~/.aws/credentials.
 */
export function credentials() {
  const env = process.env;
  if (env.AWS_ACCESS_KEY_ID && env.AWS_SECRET_ACCESS_KEY) {
    return { accessKey: env.AWS_ACCESS_KEY_ID, secretKey: env.AWS_SECRET_ACCESS_KEY, token: env.AWS_SESSION_TOKEN ?? null };
  }
  const profile = env.AWS_PROFILE ?? 'default';
  let text = '';
  try {
    text = readFileSync(env.AWS_SHARED_CREDENTIALS_FILE ?? join(homedir(), '.aws/credentials'), 'utf8');
  } catch {
    throw new Error('No AWS credentials: set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY, or a profile in ~/.aws/credentials');
  }
  const values = {};
  let current = null;
  for (const line of text.split(/\r?\n/)) {
    const section = /^\s*\[([^\]]+)\]\s*$/.exec(line);
    if (section) {
      current = section[1].trim();
      continue;
    }
    const pair = /^\s*([^=#;\s]+)\s*=\s*(.*?)\s*$/.exec(line);
    if (pair && current === profile) values[pair[1]] = pair[2];
  }
  if (!values.aws_access_key_id || !values.aws_secret_access_key) {
    throw new Error(`No keys for the AWS profile "${profile}" in ~/.aws/credentials`);
  }
  return { accessKey: values.aws_access_key_id, secretKey: values.aws_secret_access_key, token: values.aws_session_token ?? null };
}

const sha256Hex = (data) => createHash('sha256').update(data).digest('hex');
const hmac = (key, data) => createHmac('sha256', key).update(data).digest();

/** RFC 3986 unreserved characters stay; everything else is %XX, byte by byte. */
function percentEncode(value) {
  let out = '';
  for (const byte of Buffer.from(value, 'utf8')) {
    const c = String.fromCharCode(byte);
    out += /[A-Za-z0-9\-._~]/.test(c) ? c : `%${byte.toString(16).toUpperCase().padStart(2, '0')}`;
  }
  return out;
}

function canonicalURI(key) {
  return key ? '/' + key.split('/').map(percentEncode).join('/') : '/';
}

function canonicalQuery(items) {
  return items
    .map(([k, v]) => [percentEncode(k), percentEncode(v)])
    .sort((a, b) => (a[0] === b[0] ? (a[1] < b[1] ? -1 : 1) : a[0] < b[0] ? -1 : 1))
    .map(([k, v]) => `${k}=${v}`)
    .join('&');
}

export function openS3({ bucket, region }) {
  const host = `${bucket}.s3.${region}.amazonaws.com`;
  let keys = null;

  // Signed afresh on every attempt: the date is part of the signature, and a
  // retry minutes later with the old one would be refused.
  async function request(method, key, options = {}) {
    for (let attempt = 0; ; attempt++) {
      try {
        const response = await once(method, key, options);
        if (response.status < 500 || attempt === 3) return response;
      } catch (error) {
        if (attempt === 3) throw error;
      }
      await new Promise((r) => setTimeout(r, 1000 * 2 ** attempt));
    }
  }

  async function once(method, key, { query = [], body = '', headers = {} } = {}) {
    keys ??= credentials();
    const payload = Buffer.from(body);
    const amzDate = new Date().toISOString().replace(/[-:]/g, '').replace(/\.\d{3}/, '');
    const dateStamp = amzDate.slice(0, 8);
    const payloadHash = sha256Hex(payload);
    const uri = canonicalURI(key);
    const queryString = canonicalQuery(query);

    const signed = [
      ['host', host],
      ['x-amz-content-sha256', payloadHash],
      ['x-amz-date', amzDate],
      ...(keys.token ? [['x-amz-security-token', keys.token]] : []),
    ];
    const canonicalHeaders = signed.map(([k, v]) => `${k}:${v}\n`).join('');
    const signedHeaders = signed.map(([k]) => k).join(';');
    const canonicalRequest = [method, uri, queryString, canonicalHeaders, signedHeaders, payloadHash].join('\n');
    const scope = `${dateStamp}/${region}/s3/aws4_request`;
    const stringToSign = ['AWS4-HMAC-SHA256', amzDate, scope, sha256Hex(canonicalRequest)].join('\n');
    const signingKey = hmac(hmac(hmac(hmac(`AWS4${keys.secretKey}`, dateStamp), region), 's3'), 'aws4_request');
    const signature = createHmac('sha256', signingKey).update(stringToSign).digest('hex');

    const response = await fetch(`https://${host}${uri}${queryString ? `?${queryString}` : ''}`, {
      method,
      headers: {
        ...Object.fromEntries(signed.filter(([k]) => k !== 'host')),
        Authorization: `AWS4-HMAC-SHA256 Credential=${keys.accessKey}/${scope}, SignedHeaders=${signedHeaders}, Signature=${signature}`,
        ...headers,
      },
      body: method === 'GET' || method === 'HEAD' ? undefined : payload,
    });
    return response;
  }

  return {
    /** The object's text, or null when there is none. */
    async get(key) {
      const response = await request('GET', key);
      if (response.status === 404) return null;
      if (!response.ok) throw new Error(`S3 GET ${key}: ${response.status} ${await response.text()}`);
      return response.text();
    },
    async put(key, body, { contentType, cacheControl } = {}) {
      const response = await request('PUT', key, {
        body,
        headers: {
          ...(contentType ? { 'Content-Type': contentType } : {}),
          ...(cacheControl ? { 'Cache-Control': cacheControl } : {}),
        },
      });
      if (!response.ok) throw new Error(`S3 PUT ${key}: ${response.status} ${await response.text()}`);
    },
  };
}
