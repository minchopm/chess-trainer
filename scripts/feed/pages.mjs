// The website's side of a new story: its page, the stories' sitemap, the
// Atom feed, and a word to IndexNow — written by the collector the moment the
// story is, so a story is findable within the hour rather than at the next
// deploy.
//
// The page is rendered with the site's own renderer: the Angular server bundle
// of the build that is deployed (web/src/server.ts), which the collector's
// package carries in site-server/ and which deploy.sh refreshes with every
// deploy. So a page made here is the page a deploy would have made — the same
// components, the same styles, the same chunks — and the next deploy, which
// prerenders every story, simply writes it again.
//
// What is written goes to the site's bucket, beside the deploy's files and
// under keys the deploy leaves alone: today/<id>/index.html, today/feed.xml,
// sitemap-today.xml. Only stories the feed makes public (FEED_PUBLIC) get any.
import { createHash } from 'node:crypto';
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

import { LANGS } from './article.mjs';
import { pageStory, pageURL } from './page-story.mjs';
import { openS3 } from './s3.mjs';
import { inLanguage } from './store.mjs';

/**
 * The other languages a story has a page in, as the feed names them and as
 * the site's addresses do: /de/today/<id>, /pt-br/today/<id>.
 */
export const LANGUAGES = LANGS.filter((lang) => lang !== 'en').map((lang) => ({
  lang,
  slug: { 'pt-BR': 'pt-br', 'zh-Hans': 'zh-hans', 'zh-Hant': 'zh-hant' }[lang] ?? lang,
}));

/** A story's page in one of them. */
export const languageURL = (id, slug) => `https://brasspawn.com/${slug}/today/${id}`;

const HERE = dirname(fileURLToPath(import.meta.url));

/**
 * Where the renderer is: packaged beside this file in the Lambda, and by hand
 * the last build's. A build that is not the deployed one renders pages that
 * ask for chunks the site does not have, so by hand it is worth deploying
 * first.
 */
const RENDERERS = [join(HERE, 'site-server/server.mjs'), resolve(HERE, '../../web/dist/brass-pawn/server/server.mjs')];

const ORIGIN = 'https://brasspawn.com';
/** How many stories the Atom feed carries: about a week. */
const FEED_ENTRIES = 60;

// The HTML never cached, as the deploy has it; the lists five minutes at the
// edge, as the feed's JSON has it.
const HTML = { contentType: 'text/html; charset=utf-8', cacheControl: 'no-cache,no-store,must-revalidate' };
const LIST = (contentType) => ({ contentType, cacheControl: 'public,max-age=300' });

const escape = (text) =>
  String(text ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&apos;' })[c]);

export function openPages({
  bucket = process.env.SITE_BUCKET ?? 'brasspawn.com',
  region = process.env.SITE_REGION ?? 'eu-central-1',
  indexNowKey = process.env.INDEXNOW_KEY ?? null,
  dryRun = false,
  log = console.error,
} = {}) {
  const s3 = openS3({ bucket, region });
  let renderer = null;

  let file = null;
  async function render(path, context) {
    renderer ??= (async () => {
      file = RENDERERS.find((candidate) => existsSync(candidate));
      if (!file) throw new Error('no site renderer — build the site, or deploy the collector with one');
      return import(pathToFileURL(file).href);
    })();
    return (await renderer).render(path, context);
  }

  /**
   * Which build the renderer is: a hash of its manifest, which names every
   * chunk the pages it renders ask for. A page rendered by an older build
   * still works — its chunks stay on the site — but it is that build's page,
   * so the other languages are rendered again, a story at a time, until every
   * one is this build's.
   */
  let buildHash = null;
  async function build() {
    if (!buildHash) {
      await render('/404', null).catch(() => null);
      const manifest = join(dirname(file), 'angular-app-manifest.mjs');
      buildHash = createHash('sha1').update(readFileSync(manifest)).digest('hex').slice(0, 12);
    }
    return buildHash;
  }

  async function put(key, body, options) {
    if (dryRun) {
      log(`  would write s3://${bucket}/${key} (${Buffer.byteLength(body)} bytes)`);
      return;
    }
    await s3.put(key, body, options);
  }

  return {
    /** A story's page: rendered, and written where the site serves it. */
    async page(story) {
      const html = await render(`/today/${story.id}`, { story: pageStory(story) });
      // The renderer answers a story it cannot place with the site's 404; a
      // page that says the story is missing is worse than no page.
      if (!html || !html.includes(`<link rel="canonical" href="${pageURL(story.id)}"`)) {
        throw new Error(`the renderer did not make a page for ${story.id}`);
      }
      await put(`today/${story.id}/index.html`, html, HTML);
      return pageURL(story.id);
    },

    build,

    /**
     * A story's pages in every other language, from each language's copy of
     * it. Rendered one after another — the renderer is one process — and
     * written side by side.
     */
    async translations(story) {
      const pages = [];
      for (const { lang, slug } of LANGUAGES) {
        const html = await render(`/${slug}/today/${story.id}`, { story: pageStory(inLanguage(story, lang)) });
        if (!html || !html.includes(`<link rel="canonical" href="${languageURL(story.id, slug)}"`)) {
          throw new Error(`the renderer did not make the ${slug} page for ${story.id}`);
        }
        pages.push({ key: `${slug}/today/${story.id}/index.html`, html, url: languageURL(story.id, slug) });
      }
      await Promise.all(pages.map(({ key, html }) => put(key, html, HTML)));
      return pages.map(({ url }) => url);
    },

    /**
     * The stories' sitemap and the Atom feed, from every public story, newest
     * first — written whole each time, so a run that follows a deploy puts back
     * anything the deploy's timing left out.
     */
    async lists(stories, translated = {}) {
      const withPages = stories.filter((story) => story.url === pageURL(story.id));
      const entry = (loc, story) => `  <url>\n    <loc>${escape(loc)}</loc>\n    <lastmod>${escape(lastmod(story))}</lastmod>\n  </url>`;
      // The story in English, and in every language it has been rendered in.
      const urls = withPages
        .flatMap((story) => [
          entry(story.url, story),
          ...(translated[story.id] ? LANGUAGES.map(({ slug }) => entry(languageURL(story.id, slug), story)) : []),
        ])
        .join('\n');
      await put(
        'sitemap-today.xml',
        `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${urls}\n</urlset>\n`,
        LIST('application/xml; charset=utf-8'),
      );
      await put('today/feed.xml', atom(withPages.slice(0, FEED_ENTRIES)), LIST('application/atom+xml; charset=utf-8'));
      log(`  sitemap-today.xml and today/feed.xml: ${withPages.length} stories, ${Object.keys(translated).length} of them in every language`);
    },

    /** Bing and the engines that share its endpoint, told about the new pages. */
    async announce(urls) {
      if (!urls.length) return;
      if (!indexNowKey) {
        log('  IndexNow: no key, nothing sent');
        return;
      }
      if (dryRun) {
        log(`  would tell IndexNow about ${urls.length} pages`);
        return;
      }
      try {
        const response = await fetch('https://api.indexnow.org/indexnow', {
          method: 'POST',
          headers: { 'content-type': 'application/json; charset=utf-8', 'user-agent': 'Brass-Pawn-IndexNow/1.0' },
          body: JSON.stringify({
            host: new URL(ORIGIN).hostname,
            key: indexNowKey,
            keyLocation: `${ORIGIN}/${indexNowKey}.txt`,
            urlList: urls,
          }),
          signal: AbortSignal.timeout(20_000),
        });
        log(`  IndexNow: HTTP ${response.status} for ${urls.length} pages`);
      } catch (error) {
        // Never the run's failure: the pages are written, and the sitemap has them.
        log(`  IndexNow: ${error.message}`);
      }
    },
  };
}

/**
 * Every public story given its page, and the lists made from them.
 *
 * A story whose address is still the feed's stand-in either has a page already
 * — the deploy prerendered it — and is told so, or has none, and is given
 * one. So this is what makes the history's pages, the first time, and what
 * retries a page that failed to render on an earlier run. Returns the pages it
 * wrote, for whoever tells the search engines.
 */
export async function publishPages({ store, site, days, log = console.error, translated = null }) {
  const stories = await store.publicStories(days);
  const changed = [];
  const written = [];
  for (const story of stories) {
    if (story.url === pageURL(story.id)) continue;
    try {
      if (!(await live(story.id))) written.push(await site.page(story));
      changed.push({ ...story, url: pageURL(story.id) });
    } catch (error) {
      log(`  ✗ page for ${story.id}: ${error.message}`);
    }
  }
  if (changed.length) {
    await store.write(changed, days);
    log(`  ${changed.length} stories given their page's address, ${written.length} of them a new page`);
  }
  const byId = new Map(changed.map((story) => [story.id, story]));
  await site.lists(stories.map((story) => byId.get(story.id) ?? story), translated ?? (await store.pages()).done);
  return written;
}

/**
 * Every public story's pages in the other languages, rendered by this build:
 * newest first, as many as the time allows, and the rest on the next run. A
 * new story is the newest, so it is always among the first; after a site
 * deploy the whole history is rendered again, a run or two at most. Returns
 * the pages rendered for the first time, for whoever tells the search
 * engines, and the record of which stories are done.
 */
export async function translatePages({ store, site, days, budgetMs, log = console.error }) {
  const started = Date.now();
  const build = await site.build();
  const pages = await store.pages();
  const stories = await store.publicStories(days);
  const fresh = [];
  let rendered = 0;
  for (const summary of stories) {
    if (pages.done[summary.id] === build) continue;
    if (Date.now() - started > budgetMs) break;
    const story = await store.story(summary.id);
    if (!story) continue;
    try {
      const urls = await site.translations(story);
      if (!pages.done[summary.id]) fresh.push(...urls);
      pages.done[summary.id] = build;
      rendered++;
      if (rendered % 10 === 0) await store.savePages(pages);
    } catch (error) {
      log(`  ✗ languages for ${summary.id}: ${error.message}`);
    }
  }
  if (rendered) await store.savePages(pages);
  const left = stories.filter((story) => pages.done[story.id] !== build).length;
  log(`  ${rendered} stories rendered in every language by build ${build}; ${left} to go`);
  return { fresh, done: pages.done, left };
}

/** Whether the site already serves this story's page. */
async function live(id) {
  const response = await fetch(`${ORIGIN}/today/${id}`, { method: 'HEAD', signal: AbortSignal.timeout(20_000) });
  if (response.status === 200) return true;
  if (response.status === 404) return false;
  throw new Error(`the site answered ${response.status} for ${id}`);
}

/** When a story last changed — its own day for one never touched since. */
function lastmod(story) {
  return story.updatedAt ?? story.date;
}

function atom(stories) {
  const updated = stories.map(lastmod).sort().at(-1) ?? new Date().toISOString();
  const stamp = (value) => (value.length === 10 ? `${value}T00:00:00Z` : value);
  const entries = stories
    .map(
      (story) => `  <entry>
    <title>${escape(story.headline)}</title>
    <link href="${escape(story.url)}"/>
    <id>${escape(story.url)}</id>
    <published>${stamp(story.date)}</published>
    <updated>${escape(stamp(lastmod(story)))}</updated>
    <summary>${escape(story.lede ?? '')}</summary>
  </entry>`,
    )
    .join('\n');
  return `<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Brass Pawn — Today</title>
  <subtitle>The finished games from the day's top events, and the move where the engine says each one turned.</subtitle>
  <link href="${ORIGIN}/today/feed.xml" rel="self"/>
  <link href="${ORIGIN}/today"/>
  <id>${ORIGIN}/today</id>
  <updated>${escape(stamp(updated))}</updated>
  <author><name>Brass Pawn</name></author>
${entries}
</feed>
`;
}

// By hand: every public story given its page, and the lists rewritten.
//
//   node scripts/feed/pages.mjs              the history's pages and lists
//   node scripts/feed/pages.mjs --dry-run    say what it would write
if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  const { openStore } = await import('./store.mjs');
  const dryRun = process.argv.includes('--dry-run');
  const store = openStore({ dryRun });
  const site = openPages({ dryRun, indexNowKey: process.env.INDEXNOW_KEY ?? keyFromSite() });
  const { days } = await store.state();
  const written = await publishPages({ store, site, days });
  await site.announce(written);
  console.error(`${written.length} pages written`);
}

/** The IndexNow key, by hand: the one key file the site serves. */
function keyFromSite() {
  const files = readdirSync(resolve(HERE, '../../web/public')).filter((name) => /^[a-f0-9-]{8,128}\.txt$/i.test(name));
  return files.length === 1 ? files[0].slice(0, -4) : null;
}
