import { ChangeDetectionStrategy, Component, inject, input, computed } from '@angular/core';
import { RouterLink } from '@angular/router';

import { Reveal } from '../../core/reveal';
import { Seo } from '../../core/seo';
import { FAQ, SITE, url } from '../../core/site';
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

  /** This page's words, short. */
  protected readonly c = computed(() => this.pages().support);

  protected readonly site = SITE;
  protected readonly faq = FAQ;

  constructor() {
    inject(Seo).apply({
      path: '/support',
      title: 'Support',
      description:
        'How to reach a human about Brass Pawn, what to include when reporting a wrong ' +
        'puzzle, and the questions that get asked most.',
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
  }
}
