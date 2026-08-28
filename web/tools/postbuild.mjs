/**
 * Two things the Angular build does not do for a static host: a sitemap, and a
 * 404 page at the path servers actually look for.
 */
import { copyFile, readFile, readdir, stat, writeFile } from 'node:fs/promises';
import { join } from 'node:path';

const OUT = 'dist/brass-pawn/browser';
const ORIGIN = 'https://brasspawn.com';

const { locales } = JSON.parse(await readFile(new URL('./locales.json', import.meta.url), 'utf8'));

/**
 * Languages whose four commercial pages are translated.
 *
 * Read out of the loader rather than listed again here. That file is what the
 * router generates its routes from, so a language named in one place and not
 * the other would put a URL in the sitemap that nothing renders — and the
 * assertion at the foot of this script would fail the build, which is the
 * cheapest place to find out.
 */
const pagesTs = await readFile(new URL('../src/app/i18n/pages.ts', import.meta.url), 'utf8');
const PAGE_LOCALES = [...pagesTs.matchAll(/import\('\.\/pages\/([a-z-]+)'\)/g)].map((m) => m[1]);

/** The four that are translated, and the seven essays that stay in English. */
const TRANSLATED_PAGES = ['/training', '/tactics', '/pricing', '/support'];

/**
 * One alternates block per inner page, naming only the languages that have it.
 *
 * Not the block above: that one names the home pages. A page whose hreflang set
 * points at addresses in a different group is a group whose members disagree
 * about who is in it, which is the case the note above says gets discarded.
 */
const pageAlternates = (path) =>
  [
    `    <xhtml:link rel="alternate" hreflang="en" href="${ORIGIN}${path}"/>`,
    ...PAGE_LOCALES.filter((slug) => slug !== 'en').map(
      (slug) =>
        `    <xhtml:link rel="alternate" hreflang="${locales.find((l) => l.slug === slug).tag}" href="${ORIGIN}/${slug}${path}"/>`,
    ),
    `    <xhtml:link rel="alternate" hreflang="x-default" href="${ORIGIN}${path}"/>`,
  ].join('\n');

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
  { path: '/training', priority: '0.9', changefreq: 'monthly', alternates: '/training' },
  { path: '/tactics', priority: '0.9', changefreq: 'monthly', alternates: '/tactics' },
  { path: '/watch', priority: '0.9', changefreq: 'monthly' },
  { path: '/ratings', priority: '0.8', changefreq: 'monthly' },
  { path: '/engine', priority: '0.8', changefreq: 'monthly' },
  { path: '/pricing', priority: '0.8', changefreq: 'monthly', alternates: '/pricing' },
  { path: '/support', priority: '0.6', changefreq: 'monthly', alternates: '/support' },
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
  // The four commercial pages in every language that has them. Nothing is
  // emitted for a language that does not: the router has no route for it, so a
  // URL here would be a promise of a page that was never rendered.
  ...PAGE_LOCALES.filter((slug) => slug !== 'en').flatMap((slug) =>
    TRANSLATED_PAGES.map((path) => ({
      path: `/${slug}${path}`,
      priority: path === '/support' ? '0.6' : '0.8',
      changefreq: 'monthly',
      alternates: path,
    })),
  ),
];

const today = new Date().toISOString().slice(0, 10);

// Written by hand rather than by a library, because it is eight lines of XML.
const body = PAGES.map(
  (page) => `  <url>
    <loc>${ORIGIN}${page.path === '/' ? '/' : page.path}</loc>
    <lastmod>${today}</lastmod>
    <changefreq>${page.changefreq}</changefreq>
    <priority>${page.priority}</priority>
${page.translated ? ALTERNATES + '\n' : page.alternates ? pageAlternates(page.alternates) + '\n' : ''}  </url>`,
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

// ── llms.txt ────────────────────────────────────────────────────────────────
//
// The convention answer engines are converging on: one markdown file that says
// what the thing is and where the real pages are, so a model does not have to
// infer it from navigation and boilerplate.
//
// The numbers are read out of src/app/core/site.ts rather than typed here,
// and the read is asserted: a page and a summary of that page disagreeing is
// the whole failure mode this file introduces, so it fails the build instead.
const siteTs = await readFile(new URL('../src/app/core/site.ts', import.meta.url), 'utf8');

// Counts get thousands separators; ratings do not. "rated 760 to 2,800" is a
// number written the way nobody writes a chess rating.
const plain = (name) => number(name, false);
const number = (name, group = true) => {
  const match = siteTs.match(new RegExp(`\\b${name}:\\s*([0-9_]+)`));
  if (!match) throw new Error(`postbuild: LIBRARY.${name} not found in site.ts — llms.txt would lie`);
  const value = Number(match[1].replace(/_/g, ''));
  return group ? value.toLocaleString('en-US') : String(value);
};
const text = (name) => {
  const match = siteTs.match(new RegExp(`\\b${name}:\\s*'([^']+)'`));
  if (!match) throw new Error(`postbuild: SITE.${name} not found in site.ts — llms.txt would lie`);
  return match[1];
};

const languages = locales.map((l) => l.name).join(', ');

await writeFile(
  join(OUT, 'llms.txt'),
  `# Brass Pawn

> ${text('category').replace(/^a /, 'A ')}. Tactics, positional judgement, endgame
> technique, coached play and a library of master games, with two chess engines
> running on the device. No account, no analytics, no advertising, and no
> network requests at all.

Brass Pawn is published by ${text('publisher')} and is free software under the
${text('licence')}. The complete source is at ${text('repo')}.

## What is in it

- ${number('tactics')} tactics puzzles, rated ${plain('ratingFloor')} to ${plain('ratingCeiling')}, most from the Lichess database (CC0)
- ${number('classics')} master games to watch, every one decisive, between two named players, short or famous
- ${number('games')} rated games to judge in Guess the Elo, both players within 150 points of each other
- ${number('positional')} positional judgement exercises, engine-screened, with no forced win in any of them
- ${number('endgames')} endgame drills, every label verified against a deep search
- Two engines: Stockfish 18 (GPLv3) and Reckless (AGPLv3). One is chosen in Settings and plays, grades and labels everything. Stockfish can play down to a rating; Reckless has no strength limiter.
- Move grading uses win probability rather than centipawns, so a hundred centipawns lost in a level position is not graded the same as a hundred lost while a queen up.
- Online play over Game Center, with no engine assistance on either side.
- ${locales.length} languages, including the chess vocabulary: ${languages}.

## What it costs

Playing is free and unlimited — against the engine, against a person, and the
whole ${number('classics')}-game library. The training is metered: five a day of each kind on a
free account, resetting at nine in the morning local time. Pro removes the limit
at $3.99 a month or $49.99 once. There is no advertising anywhere in the app.

## Pages

- [Home](${ORIGIN}/): what the app is, the eight modes, the films, pricing
- [The training](${ORIGIN}/training): each mode in full, and how a puzzle is mined and verified
- [Watch](${ORIGIN}/watch): the ${number('classics')}-game library — what got in, what did not, and taking a position over
- [The twenty tactical motifs](${ORIGIN}/tactics): fork, pin, skewer and the rest, with how many puzzles turn on each
- [What a rating measures](${ORIGIN}/ratings): why a puzzle rating is not a FIDE rating
- [The engines](${ORIGIN}/engine): both of them, win-probability grading, and what copyleft costs
- [Pricing](${ORIGIN}/pricing): the whole allowance, free against Pro
- [Support](${ORIGIN}/support): how to reach a human, and the FAQ
- [Privacy Policy](${ORIGIN}/privacy)
- [Terms of Service](${ORIGIN}/terms)
- [Licences and attribution](${ORIGIN}/licences): every third-party component and where its source is

## Other languages

The product page exists in all ${locales.length} languages at \`${ORIGIN}/<code>\`, for example
${locales.filter((l) => l.slug !== 'en').slice(0, 4).map((l) => `${ORIGIN}/${l.slug}`).join(', ')}.
The pages above are in English only.
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
  `postbuild: sitemap and llms.txt written, ${PAGES.length} urls (${locales.length} languages), ` +
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
