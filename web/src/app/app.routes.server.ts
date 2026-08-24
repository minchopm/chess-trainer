import { RenderMode, ServerRoute } from '@angular/ssr';

/**
 * Everything is prerendered. The site has no data of its own and no user
 * state, so a static file is not a compromise — it is the correct artefact.
 */
export const serverRoutes: ServerRoute[] = [{ path: '**', renderMode: RenderMode.Prerender }];
