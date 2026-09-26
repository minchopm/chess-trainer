import { AngularAppEngine, createRequestHandler } from '@angular/ssr';

/**
 * The site's own renderer, for the one page the build cannot make in advance.
 *
 * Every page is prerendered at deploy, and that stays the site. But the feed
 * grows every two hours and the site is deployed when somebody deploys it, so
 * a story newer than the last deploy would have no page. The collector renders
 * it instead, with this — the same components, templates and styles the
 * prerenderer used, so the page it writes is the page a deploy would have
 * written. Nothing serves requests with it: it runs inside the collector, once
 * per new story, and the HTML goes to the site's bucket like any other page.
 */
const engine = new AngularAppEngine();

/**
 * One page, as HTML. `context` reaches the app as REQUEST_CONTEXT: a new
 * story travels in it, because the build's own list of stories does not
 * have it.
 */
export async function render(path: string, context?: unknown): Promise<string | null> {
  const response = await engine.handle(new Request(`https://brasspawn.com${path}`), context);
  if (!response || !response.ok) return null;
  return response.text();
}

/** For the Angular CLI's dev server, which looks for this name. */
export const reqHandler = createRequestHandler((request) => engine.handle(request));
