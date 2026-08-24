import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';

import { Reveal } from '../../core/reveal';
import { Seo } from '../../core/seo';
import { LIBRARY, SITE } from '../../core/site';
import { PageHead } from '../../shared/page-head/page-head';

/**
 * The Watch library, at length.
 *
 * Its own page rather than a section of /training because it is the one mode
 * that is not training at all — it is reading — and because "watch chess games"
 * is a thing people search for in a way that "positional judgement exercises"
 * is not.
 */
@Component({
  selector: 'bp-watch',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, PageHead, Reveal],
  templateUrl: './watch.html',
  styleUrl: './watch.scss',
})
export class Watch {
  protected readonly site = SITE;
  protected readonly library = LIBRARY;

  /**
   * What a game has to be to get in.
   *
   * Written as rules rather than as prose because they are rules: the library
   * was filtered by them, and a reader deciding whether nine hundred is a lot
   * or a little deserves to know what was thrown away.
   */
  protected readonly rules = [
    {
      rule: 'Decisive',
      why: 'A draw can be a masterpiece and almost never teaches one. Every game here ends with somebody winning, so there is always a moment where it went wrong and always a question worth asking about it.',
    },
    {
      rule: 'Two named players',
      why: 'Game scores from published collections of the players’ own games. You can look somebody up, watch four of their games in a row, and start to hear an accent in how they play — which is not something a pile of anonymous games can give you.',
    },
    {
      rule: 'Short, or famous',
      why: 'Either finished inside twenty-five moves or well known enough to have a name of its own. A ninety-move technical grind between two people you have never heard of is a library nobody opens twice.',
    },
  ] as const;

  constructor() {
    inject(Seo).apply({
      path: '/watch',
      title: 'Watch',
      updated: '2026-08-24',
      description:
        'Nine hundred decisive master games in Brass Pawn, every one between two named players and either short or famous. Search by player, event or year, follow the game move by move, and take any position over to play on yourself against the engine.',
      crumbs: [{ label: 'How the training works', path: '/training' }],
    });
  }
}
