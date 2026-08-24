import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';

import { Reveal } from '../../core/reveal';
import { Seo } from '../../core/seo';
import { FAQ, FILM, LIBRARY, MODES, PRICING, SITE } from '../../core/site';
// Statically imported rather than resolved on the route: this is the home
// page's own language, it is four kilobytes, and making the most important
// page on the site wait for a chunk before it can render would be a poor
// trade for a saving it never gets to keep.
import { copy } from '../../i18n/copy/en';
import { Showcase } from '../../shared/showcase/showcase';
import { Hero } from './hero/hero';

@Component({
  selector: 'bp-home',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, Hero, Reveal, Showcase],
  templateUrl: './home.html',
  styleUrl: './home.scss',
})
export class Home {
  protected readonly site = SITE;
  protected readonly library = LIBRARY;
  protected readonly pricing = PRICING;
  protected readonly modes = MODES;
  protected readonly film = FILM;
  protected readonly faq = FAQ.slice(0, 4);
  protected readonly copy = copy;

  protected readonly figures = [
    { value: '14,351', label: 'tactics puzzles', note: 'rated 760 to 2800' },
    { value: '116', label: 'positional exercises', note: 'no forced win in any of them' },
    { value: '15', label: 'endgame drills', note: 'every label engine-verified' },
    { value: '1,624', label: 'rated games', note: 'for Guess the Elo' },
    { value: '31', label: 'languages', note: 'chess vocabulary translated, not guessed' },
    { value: '0', label: 'bytes sent anywhere', note: 'there is no server of ours' },
  ] as const;

  constructor() {
    inject(Seo).apply({
      path: '/',
      title: SITE.name,
      description:
        'Brass Pawn for iPhone and iPad: 14,351 tactics puzzles, positional judgement, ' +
        'engine-verified endgames, Rush, Guess the Elo and coached play — with Stockfish ' +
        'running on the device. No account, no analytics, no advertising.',
      updated: '2026-08-19',
      // This page is the English member of the translated set and the
      // x-default. hreflang is reciprocal — a group whose pages do not all
      // name each other is discarded whole — so the root has to declare the
      // same thirty-one alternates that /de and /ja do.
      translated: true,
    });
  }
}
