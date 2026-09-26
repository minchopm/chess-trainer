import { afterNextRender, ChangeDetectionStrategy, Component, computed, inject, input, signal } from '@angular/core';

import { Reveal } from '../../core/reveal';
import { Seo } from '../../core/seo';
import { SITE } from '../../core/site';
import { PageHead } from '../../shared/page-head/page-head';
import { FEED } from './feed';
import type { StorySummary } from './feed/types';
import { feedFolder, listPath, STORY_SLUGS, TodayLanguage } from './i18n';
import { liveStories } from './live';
import { StoryCard } from './story-card';

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
  /** From the route, on the pages in another language: that language's list. */
  readonly feed = input<readonly StorySummary[] | undefined>(undefined);

  private readonly language = inject(TodayLanguage);
  protected readonly w = this.language.words;
  /** The first paragraph about how it is made, split round the one word that is a link. */
  protected readonly how = computed(() => {
    const [before, ...after] = this.w().howP1.split('Lichess');
    return { before, after: after.join('Lichess') };
  });
  protected readonly site = SITE;

  /** Stories since the last deploy, from the live feed — see live.ts. */
  private readonly live = signal<StorySummary[]>([]);

  protected readonly days = computed(() => {
    const days: { date: string; label: string; stories: StorySummary[] }[] = [];
    const all = [...this.live(), ...(this.feed() ?? FEED)].sort((a, b) => b.date.localeCompare(a.date)).slice(0, SHOWN);
    for (const story of all) {
      let day = days.at(-1);
      if (day?.date !== story.date) {
        day = { date: story.date, label: this.language.longDate(story.date), stories: [] };
        days.push(day);
      }
      day.stories.push(story);
    }
    return days;
  });

  constructor() {
    const words = this.language.words();
    inject(Seo).apply({
      path: listPath(words.slug),
      translatedPath: '/today',
      translatedIn: STORY_SLUGS,
      locale: words.locale,
      title: `${words.app['today']} — ${words.listTitle}`,
      updated: FEED[0]?.date,
      description: words.listLede,
    });
    afterNextRender(async () => {
      const own = new Set((this.feed() ?? FEED).map((story) => story.id));
      this.live.set(await liveStories(feedFolder(words.slug), own));
    });
  }
}
