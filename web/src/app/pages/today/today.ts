import { afterNextRender, ChangeDetectionStrategy, Component, computed, inject, input, signal } from '@angular/core';

import { Reveal } from '../../core/reveal';
import { Seo } from '../../core/seo';
import { SITE } from '../../core/site';
import { PageHead } from '../../shared/page-head/page-head';
import { reportWords } from '../reports/words';
import { FEED } from './feed';
import { REPORT_LINKS } from './feed/reports';
import type { ReportLink, StorySummary } from './feed/types';
import { feedFolder, listPath, reportPath, STORY_SLUGS, TodayLanguage } from './i18n';
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

  /**
   * The Olympiad's reports: the event's and the latest round's, as this build
   * has them, and then as the live index has them — a round finished since
   * the last deploy has its report the same hour.
   */
  private readonly liveReports = signal<readonly ReportLink[] | null>(null);
  protected readonly reports = computed(() => {
    const slug = this.w().slug;
    return (this.liveReports() ?? REPORT_LINKS[slug] ?? REPORT_LINKS['en'] ?? []).map((link) => ({
      ...link,
      path: reportPath(link.id, slug),
    }));
  });
  protected readonly r = computed(() => reportWords(this.w().slug));

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
      this.liveReports.set(await liveReports(feedFolder(words.slug)));
    });
  }
}

/** The event's report and the latest round's, from the live index in a language; null if it cannot be read. */
async function liveReports(folder: string | null): Promise<ReportLink[] | null> {
  try {
    const response = await fetch(`/media/feed/v1/${folder ? `${folder}/` : ''}reports/index.json`);
    if (!response.ok) return null;
    const { reports = [] } = (await response.json()) as { reports?: ReportLink[] };
    return [reports.find((r) => r.kind === 'event'), reports.find((r) => r.kind === 'round')]
      .filter((r): r is ReportLink => !!r)
      .map(({ id, kind, round, headline }) => ({ id, kind, round, headline }));
  } catch {
    return null;
  }
}
