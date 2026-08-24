import { ChangeDetectionStrategy, Component, computed, effect, inject, input } from '@angular/core';
import { RouterLink } from '@angular/router';

import { Reveal } from '../../core/reveal';
import { Seo } from '../../core/seo';
import { faqPage, filmList } from '../../core/schema';
import { LIBRARY, PRICING, SITE, url } from '../../core/site';
import type { Locale } from '../../i18n/locales';
import type { Copy } from '../../i18n/types';
import { Showcase } from '../../shared/showcase/showcase';

/**
 * The product page, in one of thirty-one languages.
 *
 * It is not a translation of the English home page and is not meant to be. The
 * English site is an essay — several thousand words about what a rating
 * measures and why the engine is licensed the way it is — and machine-turning
 * that into thirty languages would produce thirty pages nobody would want to
 * read and nobody could vouch for.
 *
 * This page argues the same case with evidence instead of prose: the app
 * running in the visitor's own language, a person speaking it, and the
 * sentences the app itself uses about itself — every one of which was already
 * translated by somebody, for the app or for its App Store listing. The long
 * essays stay in English and are linked as what they are.
 */
@Component({
  selector: 'bp-locale',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, Reveal, Showcase],
  templateUrl: './locale.html',
  styleUrl: './locale.scss',
})
export class LocalePage {
  /** Resolved by the router before the page renders. See app.routes.ts. */
  readonly copy = input.required<Copy>();
  readonly locale = input.required<Locale>();

  protected readonly site = SITE;
  protected readonly library = LIBRARY;
  protected readonly pricing = PRICING;

  protected readonly slug = computed(() => this.locale().slug);

  /**
   * The counts, formatted in the visitor's own locale — 14,351 in English,
   * 14.351 in German, ١٤٬٣٥١ in Arabic. A number written the wrong way is a
   * small thing that reads as a page translated by somebody who was not paying
   * attention.
   */
  protected readonly figures = computed(() => {
    const tag = this.locale().tag;
    const n = (v: number) => v.toLocaleString(tag);
    const modes = this.copy().modes;
    return [
      { value: n(LIBRARY.tactics), label: modes.tactics },
      { value: n(LIBRARY.classics), label: modes.watch },
      { value: n(LIBRARY.games), label: modes.guess },
      { value: n(LIBRARY.positional), label: modes.positional },
      { value: n(LIBRARY.endgames), label: modes.endgames },
    ];
  });

  /**
   * The four questions, each answered in the app's own words.
   *
   * Only the questions were written for this site; every answer is a string
   * the app already ships, which is why there are four rather than the seven
   * the English page asks. A question whose answer would have to be invented
   * in thirty languages is a question this page does not ask.
   */
  protected readonly faq = computed(() => {
    const { ui, said } = this.copy();
    return [
      { q: ui.faq[0], a: said.privacy },
      { q: ui.faq[1], a: `${said.freeForever} ${said.allowance}` },
      { q: ui.faq[2], a: said.renewal },
      { q: ui.faq[3], a: `${said.freeSoftware} ${said.stockfish}` },
    ];
  });

  /** The essays, which exist in English only and say so. */
  protected readonly deeper = [
    { path: '/training', key: 'training' },
    { path: '/tactics', key: 'tactics' },
    { path: '/watch', key: 'watch' },
    { path: '/ratings', key: 'ratings' },
    { path: '/engine', key: 'engine' },
  ] as const;

  /**
   * Their titles, left in English on purpose.
   *
   * A translated label on a link to an English page is a promise the page then
   * breaks. The label is the name of the thing at the other end.
   */
  protected readonly english: Record<string, string> = {
    training: 'How the training works',
    tactics: 'The twenty tactical motifs',
    watch: 'Nine hundred games worth watching',
    ratings: 'What a rating actually measures',
    engine: 'Stockfish, and why the licence matters',
  };

  private readonly seo = inject(Seo);
  constructor() {
    effect(() => {
      const { ui, said, spoken } = this.copy();
      const locale = this.locale();
      this.seo.apply({
        // The title tag is the product name and what it is, in this language.
        // "Brass Pawn" alone is unsearchable — it was chosen to be ownable, and
        // ownable means it says nothing until the category is said next to it.
        title: ui.category,
        // The app's own description of itself, not a second translation of it.
        description: said.lede,
        path: locale.slug === 'en' ? '/' : `/${locale.slug}`,
        locale,
        translated: true,
        entities: [
          filmList(this.path(), locale.slug, locale.tag, [
            { clip: 'play', name: this.copy().modes.play, description: spoken.play },
            { clip: 'tactics', name: this.copy().modes.tactics, description: spoken.tactics },
            { clip: 'watch', name: this.copy().modes.watch, description: spoken.watch },
          ]),
          faqPage(this.path(), locale.tag, this.faq()),
        ],
      });
    });
  }

  private path(): string {
    const slug = this.locale().slug;
    return slug === 'en' ? '/' : `/${slug}`;
  }
}
