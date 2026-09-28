// DynamoDB over plain HTTPS, signed by hand — no SDK, as s3.mjs does for S3.
//
// Only what presence needs: put an item, delete one, scan the table. The JSON
// protocol, SigV4 with the service called "dynamodb", and the session token
// Lambda's credentials come with.
import { createHash, createHmac } from 'node:crypto';

import { credentials } from '../feed/s3.mjs';

const sha256Hex = (data) => createHash('sha256').update(data).digest('hex');
const hmac = (key, data) => createHmac('sha256', key).update(data).digest();

export function openDynamo({ region }) {
  const host = `dynamodb.${region}.amazonaws.com`;
  let keys = null;

  async function call(action, body) {
    keys ??= credentials();
    const payload = JSON.stringify(body);
    const amzDate = new Date().toISOString().replace(/[-:]/g, '').replace(/\.\d{3}/, '');
    const dateStamp = amzDate.slice(0, 8);
    const signed = [
      ['content-type', 'application/x-amz-json-1.0'],
      ['host', host],
      ['x-amz-date', amzDate],
      ...(keys.token ? [['x-amz-security-token', keys.token]] : []),
      ['x-amz-target', `DynamoDB_20120810.${action}`],
    ];
    const canonicalHeaders = signed.map(([k, v]) => `${k}:${v}\n`).join('');
    const signedHeaders = signed.map(([k]) => k).join(';');
    const canonicalRequest = ['POST', '/', '', canonicalHeaders, signedHeaders, sha256Hex(payload)].join('\n');
    const scope = `${dateStamp}/${region}/dynamodb/aws4_request`;
    const stringToSign = ['AWS4-HMAC-SHA256', amzDate, scope, sha256Hex(canonicalRequest)].join('\n');
    const signingKey = hmac(hmac(hmac(hmac(`AWS4${keys.secretKey}`, dateStamp), region), 'dynamodb'), 'aws4_request');
    const signature = createHmac('sha256', signingKey).update(stringToSign).digest('hex');
    const response = await fetch(`https://${host}/`, {
      method: 'POST',
      headers: {
        ...Object.fromEntries(signed.filter(([k]) => k !== 'host')),
        Authorization: `AWS4-HMAC-SHA256 Credential=${keys.accessKey}/${scope}, SignedHeaders=${signedHeaders}, Signature=${signature}`,
      },
      body: payload,
    });
    const text = await response.text();
    if (!response.ok) throw new Error(`DynamoDB ${action}: ${response.status} ${text}`);
    return text ? JSON.parse(text) : {};
  }

  return {
    put: (table, item) => call('PutItem', { TableName: table, Item: item }),
    remove: (table, key) => call('DeleteItem', { TableName: table, Key: key }),
    /** Every item the filter lets through, over as many pages as it takes. */
    async scan(table, filter) {
      const items = [];
      let start;
      do {
        const page = await call('Scan', { TableName: table, ...filter, ...(start ? { ExclusiveStartKey: start } : {}) });
        items.push(...(page.Items ?? []));
        start = page.LastEvaluatedKey;
      } while (start);
      return items;
    },
  };
}
