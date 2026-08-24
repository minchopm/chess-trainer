import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';

import { Reveal } from '../../core/reveal';
import { Seo } from '../../core/seo';
import { LIBRARY, url } from '../../core/site';
import { PageHead } from '../../shared/page-head/page-head';

const QUESTIONS = [
  {
    q: 'Why is my puzzle rating so much higher than my game rating?',
    a: 'Because a puzzle tells you something a game does not: that there is something to find, and that it is findable right now. That single piece of information is worth several hundred rating points. A puzzle rating measures how hard a position you can solve when you already know it is solvable; a game rating measures whether you notice in the first place.',
  },
  {
    q: 'How do Lichess, chess.com and FIDE ratings compare?',
    a: 'They do not convert, and any table that says otherwise is folklore. Each is a self-contained scale calibrated against its own pool of players, and the pools differ in strength, in time control and in how many games a rating is based on. As a direction rather than a formula: online ratings generally read higher than FIDE, and Lichess generally reads higher than chess.com — but the gap varies by hundreds of points depending on rating band and format, so treating it as a conversion produces a wrong number with a confident face.',
  },
  {
    q: 'What is a good chess rating?',
    a: 'Better than yours was last year. Rating scales are relative to a pool, so a number is only meaningful next to the same number measured the same way at a different time. The useful comparison is always with yourself.',
  },
  {
    q: 'Does Brass Pawn’s rating mean anything outside the app?',
    a: 'No, and it does not pretend to. It is calibrated against the difficulty of the bundled library, which carries Lichess’ human-calibrated puzzle ratings for most of its 14,351 positions. It measures your progress against the library, not your strength against a field of humans on a clock.',
  },
];

@Component({
  selector: 'bp-ratings',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, PageHead, Reveal],
  templateUrl: './ratings.html',
  styleUrl: './ratings.scss',
})
export class Ratings {
  protected readonly library = LIBRARY;
  protected readonly questions = QUESTIONS;

  protected readonly bands = [
    {
      range: '760 – 1200',
      label: 'The pieces stop hanging',
      note: 'One-move tactics, and the habit of checking what is loose.',
    },
    {
      range: '1200 – 1500',
      label: 'Patterns, not calculation',
      note: 'Forks, pins and back-rank threats seen rather than worked out.',
    },
    {
      range: '1500 – 1800',
      label: 'Two moves deep, reliably',
      note: 'Deflections, discovered attacks, and the first quiet moves.',
    },
    {
      range: '1800 – 2100',
      label: 'The point is further away',
      note: 'Long forcing lines, zwischenzugs, and sacrifices you can verify.',
    },
    {
      range: '2100 – 2500',
      label: 'Quiet moves and judgement',
      note: 'Positions where nothing forcing works and something still wins.',
    },
    {
      range: '2500 – 2800',
      label: 'The top of the library',
      note: 'Points that lie deeper than most engines are searched at.',
    },
  ] as const;

  constructor() {
    inject(Seo).apply({
      path: '/ratings',
      title: 'What a chess rating actually measures',
      description:
        'Why puzzle ratings run hundreds of points above game ratings, why Lichess, chess.com and FIDE numbers do not convert, and what these ones claim.',
      updated: '2026-08-19',
      crumbs: [{ label: 'The training', path: '/training' }],
      entities: [
        {
          '@type': 'FAQPage',
          '@id': url('/ratings#faq'),
          mainEntity: QUESTIONS.map((item) => ({
            '@type': 'Question',
            name: item.q,
            acceptedAnswer: { '@type': 'Answer', text: item.a },
          })),
        },
      ],
    });
  }
}
