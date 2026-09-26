// Which languages the daily feed's pages are in, and where they are — small
// enough for the routes to import without taking every language's words into
// the main bundle with them. The words are in index.ts, which only the Today
// pages load.

/**
 * The languages a story has a page in besides English — every language the
 * site speaks that the collector writes stories in. Canadian English and
 * French read the English and the French pages; they are the same words.
 */
export const STORY_SLUGS: readonly string[] = [
  'ar', 'bg', 'cs', 'da', 'de', 'el', 'es', 'fi', 'fr', 'he', 'hi', 'hu', 'id', 'it', 'ja',
  'ko', 'ms', 'nl', 'no', 'pl', 'pt-br', 'ro', 'ru', 'sv', 'th', 'tr', 'vi', 'zh-hans', 'zh-hant',
];

/** The feed's folder for a site language — media/feed/v1/<folder>/ — or null for English, the top level. */
export function feedFolder(slug: string): string | null {
  const special: Record<string, string | null> = {
    en: null, 'en-ca': null, 'fr-ca': 'fr', 'pt-br': 'pt-BR', 'zh-hans': 'zh-Hans', 'zh-hant': 'zh-Hant',
  };
  return slug in special ? special[slug] : slug;
}

/** The slug a story page is in for a site language: its own, or the one it reads. */
export function storySlug(slug: string): string {
  if (slug === 'en-ca') return 'en';
  if (slug === 'fr-ca') return 'fr';
  return STORY_SLUGS.includes(slug) ? slug : 'en';
}

/** Where a story's page is, in a language. */
export function storyPath(id: string, slug: string): string {
  const own = storySlug(slug);
  return own === 'en' ? `/today/${id}` : `/${own}/today/${id}`;
}

/** Where the list is, in a language. */
export function listPath(slug: string): string {
  const own = storySlug(slug);
  return own === 'en' ? '/today' : `/${own}/today`;
}
