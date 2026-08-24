import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';

import { Reveal } from '../../core/reveal';
import { Seo } from '../../core/seo';
import { LIBRARY, MODES, SITE } from '../../core/site';
import { PageHead } from '../../shared/page-head/page-head';

@Component({
  selector: 'bp-training',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, PageHead, Reveal],
  templateUrl: './training.html',
  styleUrl: './training.scss',
})
export class Training {
  protected readonly site = SITE;
  protected readonly modes = MODES;
  protected readonly library = LIBRARY;

  /** How a mined puzzle gets from "the engine played something" to shipping. */
  protected readonly pipeline = [
    {
      step: '01',
      title: 'Play, at human strength',
      body: 'Stockfish plays itself at deliberately human-like strength — 1320 to 2500 Elo — opening with a random pick among its top few shallow choices, so the games vary instead of repeating one line forever.',
    },
    {
      step: '02',
      title: 'Screen for the property, not the blunder',
      body: 'Every position is searched at depth 12 with two candidate lines. The signal is not “somebody blundered” but the thing a puzzle actually needs: one move is far better than every alternative.',
    },
    {
      step: '03',
      title: 'Re-search deep, with a margin',
      body: 'Survivors are searched again at depth 20 with MultiPV. A candidate is kept only if the best move beats the runner-up by at least 140 centipawns and actually achieves something.',
    },
    {
      step: '04',
      title: 'Extend until it branches',
      body: 'The solution is extended move by move for as long as every one of the solver’s moves stays uniquely best. The moment there are two good answers, the puzzle ends there — so it never has a branch you could be marked wrong for taking.',
    },
    {
      step: '05',
      title: 'Verify with a fresh engine',
      body: 'The whole set is re-checked at a higher depth by a separate script with a new engine instance. On the bundled mined set that rejected 6 of 172 puzzles whose solutions stopped being unique two plies deeper. Those were dropped rather than shipped.',
    },
  ] as const;

  constructor() {
    inject(Seo).apply({
      path: '/training',
      title: 'The training',
      updated: '2026-08-24',
      description:
        'Eight modes: tactics, positional judgement, endgames, Rush, Guess the Elo, Watch, coached play and online. How the puzzles are mined, and what is free.',
    });
  }
}
