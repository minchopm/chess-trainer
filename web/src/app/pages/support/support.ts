import { ChangeDetectionStrategy, Component, inject, input, computed, effect } from '@angular/core';
import { RouterLink } from '@angular/router';

import { Reveal } from '../../core/reveal';
import { Seo } from '../../core/seo';
import { FAQ, SITE, url } from '../../core/site';
import { CurrentLocale } from '../../i18n/current';
import type { Pages } from '../../i18n/pages/types';
import { PageHead } from '../../shared/page-head/page-head';

@Component({
  selector: 'bp-support',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, PageHead, Reveal],
  templateUrl: './support.html',
  styleUrl: './support.scss',
})
export class Support {
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

  /** This page's words, short. */
  protected readonly c = computed(() => this.pages().support);

  protected readonly site = SITE;
  protected readonly faq = FAQ;

  constructor() {
    const seo = inject(Seo);
    // In an effect because the language arrives as an input, and the title, the
    // description, the canonical and the `lang` attribute all follow it.
    effect(() => {
      const locale = this.locale();
      const meta = this.c().meta;
      seo.apply({
        path: locale.slug === 'en' ? '/support' : `/${locale.slug}/support`,
        translatedPath: '/support',
        locale,
        title: meta.title,
        description: meta.description,
        updated: '2026-08-19',
        entities: [
          {
            '@type': 'FAQPage',
            '@id': url('/support#faq'),
            mainEntity: FAQ.map((item) => ({
              '@type': 'Question',
              name: item.q,
              acceptedAnswer: { '@type': 'Answer', text: item.a },
            })),
          },
        ],
      });
    });
  }
}
