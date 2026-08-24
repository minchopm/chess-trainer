import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';

import { Reveal } from '../../core/reveal';
import { Seo } from '../../core/seo';
import { LIBRARY, PRICING, SITE } from '../../core/site';
import { PageHead } from '../../shared/page-head/page-head';

@Component({
  selector: 'bp-pricing',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, PageHead, Reveal],
  templateUrl: './pricing.html',
  styleUrl: './pricing.scss',
})
export class Pricing {
  protected readonly site = SITE;
  protected readonly pricing = PRICING;
  protected readonly library = LIBRARY;

  protected readonly allowance = [
    { activity: 'Play against the engine', free: 'Unlimited', pro: 'Unlimited' },
    { activity: 'Online games over Game Center', free: 'Unlimited', pro: 'Unlimited' },
    { activity: 'Watch — the 900-game library', free: 'Unlimited', pro: 'Unlimited' },
    // Five of each, and the same five everywhere: the app stopped having a
    // ladder of different allowances, and a page that still shows one is
    // telling somebody they get less than they do.
    { activity: 'Tactics puzzles', free: '5 a day', pro: 'Unlimited' },
    { activity: 'Rush runs', free: '5 a day', pro: 'Unlimited' },
    { activity: 'Positional exercises', free: '5 a day', pro: 'Unlimited' },
    { activity: 'Endgame drills', free: '5 a day', pro: 'Unlimited' },
    { activity: 'Guess the Elo', free: '5 a day', pro: 'Unlimited' },
    { activity: 'Advertising', free: 'None', pro: 'None' },
  ] as const;

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
