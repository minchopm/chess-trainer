import assert from 'node:assert/strict';
import { readFile, access } from 'node:fs/promises';
import { JSDOM } from 'jsdom';
const root = new URL('../', import.meta.url);
const locales = JSON.parse(await readFile(new URL('tools/locales.json', root), 'utf8')).locales;
const copy = JSON.parse(await readFile(new URL('src/app/pages/guide/content.json', root), 'utf8'));
const sitemap = await readFile(new URL('dist/brass-pawn/browser/sitemap-pages.xml', root), 'utf8');
const norm = s => s.replace(/\s+/g, ' ').trim();
for (const l of locales) {
  const path = `${l.slug === 'en' ? '' : '/' + l.slug}/guides/chess-practice`;
  const html = await readFile(new URL(`dist/brass-pawn/browser${path}/index.html`, root), 'utf8');
  const doc = new JSDOM(html).window.document;
  assert.equal(doc.documentElement.lang, l.tag, l.slug);
  assert.equal(doc.documentElement.dir, l.dir, l.slug);
  assert.equal(doc.querySelector('link[rel=canonical]').href, 'https://brasspawn.com' + path);
  assert.equal(doc.querySelectorAll('link[rel=alternate][hreflang]').length, locales.length + 1);
  assert.equal(doc.querySelectorAll('article.guide h1').length, 1);
  assert.equal(norm(doc.querySelector('h1').textContent), norm(copy[l.slug].title));
  assert(!doc.querySelector('meta[name=robots]').content.includes('noindex'));
  assert(sitemap.includes(`<loc>https://brasspawn.com${path}</loc>`));
  const graphs = [...doc.querySelectorAll('script[type="application/ld+json"]')].map(s => JSON.parse(s.textContent));
  const entities = graphs.flatMap(g => g['@graph'] ?? [g]);
  const faq = entities.find(g => g['@type'] === 'FAQPage');
  assert.equal(faq.mainEntity.length, 4);
  const text = norm(doc.querySelector('article.guide').textContent);
  for (const item of faq.mainEntity) {
    assert(text.includes(norm(item.name)));
    assert(text.includes(norm(item.acceptedAnswer.text)));
  }
  for (const img of doc.querySelectorAll('article.guide img')) {
    await access(new URL(img.getAttribute('src').replace(/^\//, ''), root));
  }
}
console.log(`Verified ${locales.length} prerendered guides: content, canonical, hreflang, RTL, FAQ, sitemap and images.`);
