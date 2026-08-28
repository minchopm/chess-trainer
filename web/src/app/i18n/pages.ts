import type { Pages } from './pages/types';

/**
 * Which languages have the inner pages translated.
 *
 * The same shape as `COPY` in copy.ts and for the same reason: a static map of
 * dynamic imports is the form the bundler can see through, so a visitor to the
 * Bulgarian pricing page downloads Bulgarian and nothing else.
 *
 * Unlike `COPY` this map is deliberately incomplete. The home page has been
 * translated into every language the app ships in, because its words came from
 * the app. These pages were written for the website and have to be translated
 * from nothing, so languages arrive here one at a time — and until a language
 * is here it has no inner pages at all, which is the honest state.
 */
export const PAGES: Record<string, () => Promise<Pages>> = {
  en: () => import('./pages/en').then((m) => m.pages),
};

/** Slugs with a finished translation of the inner pages. */
export const PAGE_LOCALES = Object.keys(PAGES);
