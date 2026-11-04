import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';

import { Reveal } from '../../core/reveal';
import { faqPage, filmList } from '../../core/schema';
import { Seo } from '../../core/seo';
import { FAQ, FILM, LIBRARY, MODES, PRICING, SITE } from '../../core/site';
// Statically imported rather than resolved on the route: this is the home
// page's own language, it is four kilobytes, and making the most important
// page on the site wait for a chunk before it can render would be a poor
// trade for a saving it never gets to keep.
import { copy } from '../../i18n/copy/en';
import { Showcase } from '../../shared/showcase/showcase';
import { TodayStrip } from '../today/today-strip';
import { Hero } from './hero/hero';
import { MoreApps } from '../../shared/more-apps/more-apps';

@Component({
  selector: 'bp-home',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, Hero, Reveal, Showcase, TodayStrip, MoreApps],
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
    { value: '0', label: 'accounts or trackers', note: 'no analytics, no adverts, nothing sold' },
  ] as const;

  protected readonly featuredGuides = [
    {
      topic: 'Study plans',
      slug: 'beginner-chess-study-plan',
      title: 'A beginner chess study plan built around real mistakes',
    },
    {
      topic: 'Game review',
      slug: 'analyse-chess-game-without-engine',
      title: 'Analyse your chess game before turning on the engine',
    },
    {
      topic: 'Tactics',
      slug: 'spot-knight-forks-before-moving',
      title: 'How to spot knight forks before you move',
    },
    {
      topic: 'Calculation',
      slug: 'calculate-forcing-lines-without-tunnel-vision',
      title: 'Calculate forcing lines without following checks blindly',
    },
    {
      topic: 'Positional play',
      slug: 'rook-open-file-plan',
      title: 'Open files for rooks: find an entry square before doubling',
    },
    {
      topic: 'Endgames',
      slug: 'king-pawn-opposition',
      title: 'King and pawn opposition: decide who must give way',
    },
    {
      topic: 'Opening principles',
      slug: 'opening-development-principles',
      title: 'Opening development principles: improve pieces while answering threats',
    },
    {
      topic: 'Apps & practice',
      slug: 'choose-iphone-chess-app',
      title: 'How to choose an iPhone chess app for your actual goal',
    },
    {
      topic: 'Rules & fair play',
      slug: 'chess-engine-assistance-fair-play',
      title: 'Chess engine assistance and fair play: separate training from matches',
    },
  ] as const;

  constructor() {
    inject(Seo).apply({
      path: '/',
      title: SITE.name,
      seoTitle: 'Brass Pawn — Chess Trainer, Tactics & Offline Engine for iOS',
      description:
        '14,351 tactics puzzles, 900 master games, engine-verified endgames and coached play, with two chess engines running on your iPhone. No account, no adverts.',
      updated: '2026-11-04',
      // This page is the English member of the translated set and the
      // x-default. hreflang is reciprocal — a group whose pages do not all
      // name each other is discarded whole — so the root has to declare the
      // same thirty-one alternates that /de and /ja do.
      translated: true,
      // The same two entities the localised pages carry. This page shows the
      // same four questions and the same three films; it was the only one in
      // the set not saying so.
      entities: [
        filmList('/', 'en', 'en-US', [
          { clip: 'play', name: copy.modes.play, description: copy.spoken.play },
          { clip: 'tactics', name: copy.modes.tactics, description: copy.spoken.tactics },
          { clip: 'watch', name: copy.modes.watch, description: copy.spoken.watch },
        ]),
        faqPage('/', 'en-US', FAQ.slice(0, 4)),
      ],
    });
  }
}
