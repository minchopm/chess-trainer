import { ChangeDetectionStrategy, Component, inject, input, computed, effect } from '@angular/core';
import { RouterLink } from '@angular/router';

import { Reveal } from '../../core/reveal';
import { Seo } from '../../core/seo';
import { LIBRARY, PRICING, SITE } from '../../core/site';
import { CurrentLocale } from '../../i18n/current';
import type { Pages } from '../../i18n/pages/types';
import { PageHead } from '../../shared/page-head/page-head';

@Component({
  selector: 'bp-pricing',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, PageHead, Reveal],
  templateUrl: './pricing.html',
  styleUrl: './pricing.scss',
})
export class Pricing {
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
  protected readonly c = computed(() => this.pages().pricing);

  /**
   * The Pro list, with the library's real figures in it.
   *
   * The counts are data and the sentences around them are language, so they
   * meet here rather than being written into thirty-two translations that would
   * all have to be edited the next time a puzzle is added.
   */
  protected readonly proItems = computed(() =>
    this.c().monthly.items.map((item) =>
      item
        .replace('{tactics}', LIBRARY.tactics.toLocaleString('en-US'))
        .replace('{positional}', String(LIBRARY.positional))
        .replace('{endgames}', String(LIBRARY.endgames))
        .replace('{games}', LIBRARY.games.toLocaleString('en-US')),
    ),
  );

  /**
   * The allowance table: row labels from the language, the two values from
   * here. Five of each is the app's current shape, and the plan card above says
   * the same — it used to say one Rush run and three of the rest, which was a
   * year out of date and understated what a free account gets.
   */
  protected readonly allowance = computed(() => {
    const t = this.c().table;
    const values: readonly [string, string][] = [
      [t.unlimited, t.unlimited],
      [t.unlimited, t.unlimited],
      [t.unlimited, t.unlimited],
      [t.fiveADay, t.unlimited],
      [t.fiveADay, t.unlimited],
      [t.fiveADay, t.unlimited],
      [t.fiveADay, t.unlimited],
      [t.fiveADay, t.unlimited],
      [t.none, t.none],
    ];
    return t.rows.map((activity, i) => ({ activity, free: values[i][0], pro: values[i][1] }));
  });

  protected readonly site = SITE;
  protected readonly pricing = PRICING;
  protected readonly library = LIBRARY;

  constructor() {
    const seo = inject(Seo);
    // In an effect because the language arrives as an input, and the title, the
    // description, the canonical and the `lang` attribute all follow it.
    effect(() => {
      const locale = this.locale();
      const meta = this.c().meta;
      seo.apply({
        path: locale.slug === 'en' ? '/pricing' : `/${locale.slug}/pricing`,
        translatedPath: '/pricing',
        locale,
        title: meta.title,
        description: meta.description,
        updated: '2026-08-24',
      });
    });
  }
}
