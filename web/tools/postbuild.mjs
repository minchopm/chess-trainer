/**
 * Two things the Angular build does not do for a static host: a sitemap, and a
 * 404 page at the path servers actually look for.
 */
import { copyFile, readFile, readdir, stat, writeFile } from 'node:fs/promises';
import { join } from 'node:path';

const OUT = 'dist/brass-pawn/browser';
const ORIGIN = 'https://brasspawn.com';

const { locales } = JSON.parse(await readFile(new URL('./locales.json', import.meta.url), 'utf8'));

/** English is the site root; every other language is one segment down. */
const localePath = (locale) => (locale.slug === 'en' ? '/' : `/${locale.slug}`);

/**
 * The alternates block, identical on every page of the translated set.
 *
 * Search engines treat hreflang as a claim each page makes about the whole
 * group, and they discard a group whose members disagree about who is in it.
 * Emitting one string everywhere is not an optimisation; it is the only way to
 * be sure they agree.
 */
const ALTERNATES = [
  ...locales.map(
    (locale) =>
      `    <xhtml:link rel="alternate" hreflang="${locale.tag}" href="${ORIGIN}${localePath(locale)}"/>`,
  ),
  `    <xhtml:link rel="alternate" hreflang="x-default" href="${ORIGIN}/"/>`,
].join('\n');

/** Pages worth indexing, in the order a reader would meet them. */
const PAGES = [
  { path: '/', priority: '1.0', changefreq: 'monthly', translated: true },
  { path: '/training', priority: '0.9', changefreq: 'monthly' },
  { path: '/tactics', priority: '0.9', changefreq: 'monthly' },
  { path: '/watch', priority: '0.9', changefreq: 'monthly' },
  { path: '/ratings', priority: '0.8', changefreq: 'monthly' },
  { path: '/engine', priority: '0.8', changefreq: 'monthly' },
  { path: '/pricing', priority: '0.8', changefreq: 'monthly' },
  { path: '/support', priority: '0.6', changefreq: 'monthly' },
  { path: '/privacy', priority: '0.5', changefreq: 'yearly' },
  { path: '/terms', priority: '0.5', changefreq: 'yearly' },
  { path: '/licences', priority: '0.5', changefreq: 'yearly' },
  // The thirty other languages. Each one is a real page with its own films,
  // its own screenshots and its own words — not a machine translation of the
  // English one, which is why they are worth a crawler's time at 0.9.
  ...locales
    .filter((locale) => locale.slug !== 'en')
    .map((locale) => ({
      path: `/${locale.slug}`,
      priority: '0.9',
      changefreq: 'monthly',
      translated: true,
    })),
];

const today = new Date().toISOString().slice(0, 10);

// Written by hand rather than by a library, because it is eight lines of XML.
const body = PAGES.map(
  (page) => `  <url>
    <loc>${ORIGIN}${page.path === '/' ? '/' : page.path}</loc>
    <lastmod>${today}</lastmod>
    <changefreq>${page.changefreq}</changefreq>
    <priority>${page.priority}</priority>
${page.translated ? ALTERNATES + '\n' : ''}  </url>`,
).join('\n');

await writeFile(
  join(OUT, 'sitemap.xml'),
  `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:xhtml="http://www.w3.org/1999/xhtml">
${body}
</urlset>
`,
  'utf8',
);

// Most static hosts serve /404.html; Angular prerendered it at /404/index.html.
try {
  await copyFile(join(OUT, '404', 'index.html'), join(OUT, '404.html'));
} catch {
  console.warn('postbuild: no prerendered 404 to copy');
}

const files = await readdir(OUT, { recursive: true });
const html = files.filter((f) => f.endsWith('.html')).length;
const bytes = (
  await Promise.all(
    files.map(async (f) => {
      const info = await stat(join(OUT, f));
      return info.isFile() ? info.size : 0;
    }),
  )
).reduce((a, b) => a + b, 0);

console.log(
  `postbuild: sitemap written with ${PAGES.length} urls (${locales.length} languages), ` +
    `${html} prerendered pages, ${(bytes / 1024 / 1024).toFixed(2)} MB total`,
);

// The prerenderer is the only thing that proves the localised routes exist. If
// one of them silently stopped being generated, the sitemap would still promise
// it and the site would answer with a soft 404 in that language.
const localised = files.filter((f) => /^[a-z-]+\/index\.html$/.test(f)).length;
if (html < PAGES.length) {
  console.error(
    `postbuild: ${PAGES.length} urls in the sitemap but only ${html} pages were prerendered ` +
      `(${localised} of them one segment deep). A promised page that does not exist is worse ` +
      `than one that was never promised.`,
  );
  process.exitCode = 1;
}
