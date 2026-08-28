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
  bg: () => import('./pages/bg').then((m) => m.pages),
  es: () => import('./pages/es').then((m) => m.pages),
  fr: () => import('./pages/fr').then((m) => m.pages),
  it: () => import('./pages/it').then((m) => m.pages),
  nl: () => import('./pages/nl').then((m) => m.pages),
  pl: () => import('./pages/pl').then((m) => m.pages),
  ru: () => import('./pages/ru').then((m) => m.pages),
  cs: () => import('./pages/cs').then((m) => m.pages),
  sv: () => import('./pages/sv').then((m) => m.pages),
  da: () => import('./pages/da').then((m) => m.pages),
  no: () => import('./pages/no').then((m) => m.pages),
  fi: () => import('./pages/fi').then((m) => m.pages),
  hu: () => import('./pages/hu').then((m) => m.pages),
  ro: () => import('./pages/ro').then((m) => m.pages),
  el: () => import('./pages/el').then((m) => m.pages),
  tr: () => import('./pages/tr').then((m) => m.pages),
  id: () => import('./pages/id').then((m) => m.pages),
  ms: () => import('./pages/ms').then((m) => m.pages),
  vi: () => import('./pages/vi').then((m) => m.pages),
  ja: () => import('./pages/ja').then((m) => m.pages),
  ko: () => import('./pages/ko').then((m) => m.pages),
  'pt-br': () => import('./pages/pt-br').then((m) => m.pages),
  'fr-ca': () => import('./pages/fr-ca').then((m) => m.pages),
  'en-ca': () => import('./pages/en-ca').then((m) => m.pages),
  de: () => import('./pages/de').then((m) => m.pages),
};

/** Slugs with a finished translation of the inner pages. */
export const PAGE_LOCALES = Object.keys(PAGES);
