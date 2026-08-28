import { ChangeDetectionStrategy, Component, inject, computed, input, effect } from '@angular/core';
import { RouterLink } from '@angular/router';

import { Reveal } from '../../core/reveal';
import { Seo } from '../../core/seo';
import { LIBRARY, MOTIFS, url } from '../../core/site';
import { CurrentLocale } from '../../i18n/current';
import type { Pages } from '../../i18n/pages/types';
import { PageHead } from '../../shared/page-head/page-head';

/**
 * The tactical vocabulary, defined.
 *
 * It earns its place on a brochure site because it is the vocabulary the app
 * actually tags puzzles with — every entry ends in a real number of positions
 * that turn on it — rather than a glossary bolted on to catch searches.
 */
@Component({
  selector: 'bp-motifs',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, PageHead, Reveal],
  templateUrl: './motifs.html',
  styleUrl: './motifs.scss',
})
export class Motifs {
  /** Resolved by the router before the page renders. See app.routes.ts. */
  readonly pages = input.required<Pages>();
  /**
   * Which language this page is in.
   *
   * From CurrentLocale rather than a route input: that service already derives
   * it from the address, is seeded from `location.pathname` so it is right on
   * the first frame, and does not depend on an input default having been
   * evaluated before the effect below first runs — which it is not.
   */
  private readonly locale = inject(CurrentLocale).locale;

  protected readonly c = computed(() => this.pages().tactics);

  /**
   * The twenty motifs: slug and count from the library, the three sentences
   * about each from the language. Paired by position, so a translation cannot
   * attach the wrong count to a motif.
   */
  protected readonly motifs = computed(() =>
    MOTIFS.map((motif, i) => ({ ...motif, ...this.c().motifs[i] })),
  );

  protected readonly library = LIBRARY;

  constructor() {
    const seo = inject(Seo);
    // In an effect because the language arrives as an input, and the title, the
    // description, the canonical and the `lang` attribute all follow it.
    effect(() => {
      const locale = this.locale();
      const meta = this.c().meta;
      seo.apply({
        path: locale.slug === 'en' ? '/tactics' : `/${locale.slug}/tactics`,
        translatedPath: '/tactics',
        locale,
        title: meta.title,
        description: meta.description,
        updated: '2026-08-19',
        crumbs: [{ label: 'The training', path: '/training' }],
        entities: [
          {
            '@type': 'DefinedTermSet',
            '@id': url('/tactics#glossary'),
            name: 'Chess tactical motifs',
            description: 'The tactical vocabulary Brass Pawn tags its puzzle library with.',
            hasDefinedTerm: MOTIFS.map((motif) => ({
              '@type': 'DefinedTerm',
              '@id': url(`/tactics#${motif.slug}`),
              name: motif.name,
              description: motif.short,
              inDefinedTermSet: { '@id': url('/tactics#glossary') },
            })),
          },
          {
            '@type': 'FAQPage',
            '@id': url('/tactics#faq'),
            mainEntity: MOTIFS.slice(0, 8).map((motif) => ({
              '@type': 'Question',
              name: `What is a ${motif.name.toLowerCase()} in chess?`,
              acceptedAnswer: { '@type': 'Answer', text: `${motif.short} ${motif.body}` },
            })),
          },
        ],
      });
    });
  }
}
