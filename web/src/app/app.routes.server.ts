import { RenderMode, ServerRoute } from '@angular/ssr';

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
  { path: '**', renderMode: RenderMode.Prerender },
];
