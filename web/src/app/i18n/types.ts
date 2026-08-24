/**
 * The shape of one language.
 *
 * Split into four groups by where the words came from, because that is what
 * determines who may change them:
 *
 *   `said`  — the app's own sentences about itself, from its string catalogue.
 *   `modes` — what the app calls the seven things you can do in it.
 *   `shots` — the App Store caption written for each screenshot.
 *   `spoken` — what the narrator says to camera, in this language.
 *   `ui`    — the only strings written for the website, in tools/manual.json.
 *
 * Everything but `ui` is generated. Editing it here would put the website out
 * of step with the app the visitor is about to install, which is the one
 * mistake a localised product page cannot afford.
 */

/** A caption, written as two lines because it is read at the width of a thumb. */
export type Caption = readonly [string, string];

export interface Said {
  /** 'Play · Train · Watch' */
  readonly slug: string;
  readonly lede: string;
  readonly privacy: string;
  readonly freeSoftware: string;
  readonly stockfish: string;
  readonly reckless: string;
  readonly coaching: string;
  readonly online: string;
  readonly photo: string;
  readonly takeOver: string;
  readonly freeForever: string;
  readonly allowance: string;
  readonly noAds: string;
  readonly unlimitedPuzzles: string;
  readonly unlimitedRush: string;
  readonly unlimitedRest: string;
  readonly renewal: string;
  readonly pro: string;
  readonly monthly: string;
  readonly lifetime: string;
  readonly privacyPolicy: string;
  readonly termsOfUse: string;
  readonly licence: string;
  readonly credits: string;
}

export interface Modes {
  readonly play: string;
  readonly watch: string;
  readonly tactics: string;
  readonly positional: string;
  readonly endgames: string;
  readonly guess: string;
  readonly online: string;
  readonly progress: string;
  readonly rush: string;
}

/** Keyed by the screenshot each caption was written for. */
export interface Shots {
  readonly title: Caption;
  readonly mistake: Caption;
  readonly values: Caption;
  readonly library: Caption;
  readonly engines: Caption;
  readonly coached: Caption;
  readonly free: Caption;
}

/** One spoken line per clip, from the narrator scripts. */
export interface Spoken {
  readonly play: string;
  readonly tactics: string;
  readonly watch: string;
}

export interface Ui {
  readonly category: string;
  readonly support: string;
  readonly language: string;
  readonly menu: string;
  readonly close: string;
  readonly skip: string;
  /** Marks a link that leaves this language behind. */
  readonly inEnglish: string;
  readonly film: string;
  readonly screens: string;
  readonly price: string;
  readonly questions: string;
  readonly narrated: string;
  readonly silent: string;
  readonly play: string;
  readonly pause: string;
  readonly download: string;
  readonly soon: string;
  readonly more: string;
  readonly free: string;
  /** Why the figures beside it are dollars. */
  readonly prices: string;
  /** Four questions. The answers are in `said`, already translated. */
  readonly faq: readonly [string, string, string, string];
}

export interface Copy {
  readonly said: Said;
  readonly modes: Modes;
  readonly shots: Shots;
  readonly spoken: Spoken;
  readonly ui: Ui;
}
