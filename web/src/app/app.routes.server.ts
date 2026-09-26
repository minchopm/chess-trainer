import { RenderMode, ServerRoute } from '@angular/ssr';

import { STORY_SLUGS } from './pages/today/i18n/slugs';

/**
 * Everything is prerendered. The site has no data of its own and no user
 * state, so a static file is not a compromise — it is the correct artefact.
 *
 * The daily feed's stories are the one route with a parameter, and the
 * prerenderer has to be told which values it takes: every published story,
 * read from the same generated index the pages list them from.
 */
export const serverRoutes: ServerRoute[] = [
  {
    path: 'today/:id',
    renderMode: RenderMode.Prerender,
    async getPrerenderParams() {
      const { FEED } = await import('./pages/today/feed');
      return FEED.map((story) => ({ id: story.id }));
    },
  },
  // A story's page in another language is the collector's to render, as the
  // story is written — thirty languages of every story prerendered at every
  // deploy would be most of the deploy. The collector asks this build's
  // renderer for it (scripts/feed/pages.mjs); nothing serves it on request.
  ...STORY_SLUGS.map((slug) => ({ path: `${slug}/today/:id`, renderMode: RenderMode.Server }) as ServerRoute),
  // The Olympiad's reports, in every language: the collector's too, as it
  // writes them (scripts/feed/reports.mjs).
  { path: 'reports/:id', renderMode: RenderMode.Server },
  ...STORY_SLUGS.map((slug) => ({ path: `${slug}/reports/:id`, renderMode: RenderMode.Server }) as ServerRoute),
  { path: '**', renderMode: RenderMode.Prerender },
];
