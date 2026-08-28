/**
 * The words on the inner pages, per language.
 *
 * Kept apart from `i18n/types.ts` because of where the words come from, which
 * is the same distinction that file already draws. Everything in `Copy` is
 * lifted verbatim from the app's string catalogue, the App Store captions or
 * the narrator scripts — three corpora that were already translated for the
 * product, so the website reuses them rather than translating twice.
 *
 * None of that is true here. Not one of the 647 sentences across these ten
 * pages appears anywhere in the app's 554 English strings; it was all written
 * for the website. So it has to be translated once, by hand, and it lives in
 * its own files rather than being smuggled into `manual.json`, which exists for
 * the twenty-odd words of chrome and would stop being legible at this size.
 *
 * A language appears in `PAGES` only when its translation is finished. Routes
 * and sitemap entries are generated from that map, so a half-translated
 * language has no addresses of its own rather than a set of English pages
 * wearing its slug — which is duplicate content, and worse than absence.
 */

/** The title card every inner page opens on. */
export interface Head {
  readonly slug: string;
  readonly title: string;
  readonly lede: string;
}

/** What `Seo.apply` puts in `<title>` and the description meta. */
export interface Meta {
  readonly title: string;
  readonly description: string;
}

export interface SupportPage {
  readonly head: Head;
  readonly meta: Meta;
  readonly email: { readonly slug: string; readonly body: string };
  readonly tracker: { readonly slug: string; readonly name: string; readonly body: string };
  readonly report: {
    readonly slug: string;
    readonly title: string;
    /** Four things to send. The first contains the word FEN, which stays FEN. */
    readonly checklist: readonly [string, string, string, string];
    readonly caveat: string;
  };
  readonly faq: { readonly slug: string; readonly title: string };
  readonly more: {
    readonly ratings: string;
    readonly tactics: string;
    readonly privacy: string;
    readonly terms: string;
    readonly licences: string;
  };
}

export interface Pages {
  readonly support: SupportPage;
}
