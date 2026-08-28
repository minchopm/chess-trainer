import { ChangeDetectionStrategy, Component, inject, input, computed } from '@angular/core';
import { RouterLink } from '@angular/router';

import { Reveal } from '../../core/reveal';
import { Seo } from '../../core/seo';
import { LIBRARY, PRICING, SITE } from '../../core/site';
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
    inject(Seo).apply({
      path: '/pricing',
      title: 'Pricing',
      updated: '2026-08-24',
      description:
        'Playing is free and unlimited — the engine, a real opponent, and all 900 games. Pro lifts the five-a-day training limit: $3.99 a month or $49.99 once.',
    });
  }
}
