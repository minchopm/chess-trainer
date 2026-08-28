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

/** A question and its answer, wherever a page sets them out as a list. */
export interface Qa {
  readonly q: string;
  readonly a: string;
}

export interface PricingPage {
  readonly head: Head;
  readonly meta: Meta;
  readonly free: {
    readonly name: string;
    readonly note: string;
    readonly items: readonly string[];
  };
  readonly monthly: {
    readonly flag: string;
    readonly name: string;
    readonly per: string;
    readonly note: string;
    readonly items: readonly string[];
  };
  readonly lifetime: {
    readonly name: string;
    readonly once: string;
    readonly note: string;
    readonly items: readonly string[];
  };
  readonly table: {
    readonly slug: string;
    readonly title: string;
    readonly activity: string;
    readonly freeCol: string;
    readonly proCol: string;
    readonly unlimited: string;
    readonly fiveADay: string;
    readonly none: string;
    /** Row labels, in the order the table lists them. */
    readonly rows: readonly string[];
    readonly reset: string;
  };
  readonly why: {
    readonly slug: string;
    readonly title: string;
    readonly reasons: readonly { readonly title: string; readonly body: readonly string[] }[];
    /** The last reason ends in a link; its text is separate. */
    readonly licenceLink: string;
  };
  readonly answers: {
    readonly slug: string;
    readonly title: string;
    readonly items: readonly Qa[];
    /** The word the last answer links on. */
    readonly termsLink: string;
    readonly more: string;
  };
}

export interface TrainingPage {
  readonly head: Head;
  readonly meta: Meta;
  /**
   * The eight modes, in the order MODES lists them.
   *
   * `title` is here rather than taken from `Copy.modes` because the page names
   * two of them at greater length than the app's tab does — "Positional
   * judgement" for "Positional", "Play & coach" for "Play". A translator should
   * follow the app's word and lengthen it the way the English does.
   */
  readonly modes: readonly {
    readonly title: string;
    readonly lede: string;
    readonly body: readonly string[];
    readonly free: string;
    readonly stat?: string;
  }[];
  readonly watchLink: string;
  readonly pipeline: {
    readonly slug: string;
    readonly title: string;
    readonly lede: string;
    readonly steps: readonly { readonly title: string; readonly body: string }[];
  };
  readonly honest: { readonly title: string; readonly body: readonly string[] };
  readonly limits: {
    readonly slug: string;
    readonly title: string;
    /** The second one ends on a link; `ratingsLink` is its text. */
    readonly items: readonly { readonly title: string; readonly body: string }[];
    readonly ratingsLink: string;
  };
  readonly more: { readonly motifs: string; readonly engine: string };
}

export interface TacticsPage {
  readonly head: Head & { readonly meta: string };
  readonly meta: Meta;
  readonly indexLabel: string;
  /** The word after each count. Plural rules differ; keep it simple. */
  readonly puzzles: string;
  /** The twenty motifs, in the order MOTIFS lists them. */
  readonly motifs: readonly {
    readonly name: string;
    readonly short: string;
    readonly body: string;
  }[];
  readonly after: {
    readonly slug: string;
    readonly title: string;
    readonly body: readonly string[];
    readonly more: string;
  };
}

export interface Pages {
  readonly support: SupportPage;
  readonly pricing: PricingPage;
  readonly training: TrainingPage;
  readonly tactics: TacticsPage;
}
