import { afterNextRender, ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';

import { Reveal } from '../../core/reveal';
import { Seo } from '../../core/seo';
import { SITE } from '../../core/site';
import { PageHead } from '../../shared/page-head/page-head';
import { FEED } from './feed';
import type { StorySummary } from './feed/types';
import { liveStories } from './live';
import { StoryCard } from './story-card';
import { longDate } from './words';

/** How many stories the page lists. The rest are one link away, story to story. */
const SHOWN = 60;

/**
 * The daily feed: the finished games from the top events, newest first.
 *
 * A page of facts with an engine beside them. The moves and results are the
 * broadcast's, the evaluations are Stockfish's, and the words were written
 * from those two things and nothing else — which is what lets a page like this
 * write about real people every day without ever putting a thought in one's
 * head.
 */
@Component({
  selector: 'bp-today',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [PageHead, Reveal, StoryCard],
  templateUrl: './today.html',
  styleUrl: './today.scss',
})
export class Today {
  protected readonly site = SITE;

  /** Stories since the last deploy, from the live feed — see live.ts. */
  private readonly live = signal<StorySummary[]>([]);

  protected readonly days = computed(() => {
    const days: { date: string; label: string; stories: StorySummary[] }[] = [];
    const all = [...this.live(), ...FEED].sort((a, b) => b.date.localeCompare(a.date)).slice(0, SHOWN);
    for (const story of all) {
      let day = days.at(-1);
      if (day?.date !== story.date) {
        day = { date: story.date, label: longDate(story.date), stories: [] };
        days.push(day);
      }
      day.stories.push(story);
    }
    return days;
  });

  constructor() {
    inject(Seo).apply({
      path: '/today',
      title: 'Today — the top boards, every day',
      updated: FEED[0]?.date,
      description:
        'The finished games from the day’s top chess events, each with the move where Stockfish says it turned. Replay any of them in Brass Pawn, or play on from the key position.',
    });
    afterNextRender(async () => this.live.set(await liveStories()));
  }
}
