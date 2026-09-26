import { ChangeDetectionStrategy, Component, computed, effect, inject, input } from '@angular/core';

import { Reveal } from '../../core/reveal';
import { Seo } from '../../core/seo';
import { url } from '../../core/site';
import { PageHead } from '../../shared/page-head/page-head';
import { fill, listPath, reportPath, STORY_SLUGS, storyLocales, storyPath, TodayLanguage } from '../today/i18n';
import type { Report, ReportPlayer, ReportRow } from './types';
import { reportWords } from './words';

/** "26½", "½", "3". */
function points(n: number): string {
  const whole = Math.floor(n);
  return n % 1 ? `${whole || ''}½` : String(whole);
}

/**
 * One of the Chess Olympiad's reports: a round's — its top matches, the table
 * after it, its upsets on the ratings and its games in the feed — or the
 * event's, with every round's report under it.
 *
 * All of it counted from the relayed games, by the collector, and rendered by
 * it too (scripts/feed/reports.mjs, pages.mjs): the page draws what it is
 * handed and adds nothing. The official standings are a link away, and the
 * page says which of the two to trust for the order of teams level on points.
 */
@Component({
  selector: 'bp-report',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [PageHead, Reveal],
  templateUrl: './report-page.html',
  styleUrl: './report-page.scss',
})
export class ReportPage {
  readonly report = input.required<Report>();

  private readonly seo = inject(Seo);
  private readonly language = inject(TodayLanguage);
  protected readonly w = this.language.words;
  protected readonly r = computed(() => reportWords(this.w().slug));
  protected readonly languages = storyLocales();
  protected readonly points = points;
  protected readonly fill = fill;

  protected readonly slug = computed(() => {
    const report = this.report();
    const year = report.event.dates?.[0]?.slice(0, 4) ?? '';
    const round = report.kind === 'round' ? fill(this.w().app['round'], report.round) : null;
    return [`${this.r().section} ${year}`.trim(), round].filter(Boolean).join(' · ');
  });

  protected readonly meta = computed(() => {
    const report = this.report();
    return [report.date ? this.language.longDate(report.date) : null, report.where ?? report.event.location].filter(Boolean).join(' · ');
  });

  private readonly numberFormat = computed(() => new Intl.NumberFormat(`${this.w().locale.tag}-u-nu-latn`));
  protected number(n: number): string {
    return this.numberFormat().format(n);
  }

  protected score(score: readonly [number, number]): string {
    return `${points(score[0])}–${points(score[1])}`;
  }

  /**
   * Each row's place by match points: "1", or "=3" for every team level on
   * them with another — the order inside a tie is the official tiebreaks',
   * which the page does not claim to know.
   */
  protected readonly places = computed(() =>
    this.report().sections.map(({ table }) =>
      table.map((row: ReportRow, i) => {
        const first = table.findIndex((other) => other.mp === row.mp) + 1;
        const tied = table.some((other, j) => j !== i && other.mp === row.mp);
        return tied ? `=${first}` : String(first);
      }),
    ),
  );

  protected player(p: ReportPlayer): string {
    return [p.title, p.name].filter(Boolean).join(' ');
  }

  protected storyPath(id: string): string {
    return storyPath(id, this.w().slug);
  }
  protected reportPath(id: string, slug = this.w().slug): string {
    return reportPath(id, slug);
  }
  protected readonly list = computed(() => listPath(this.w().slug));
  protected readonly event = computed(() => this.report().kind === 'event');
  protected readonly hub = computed(() => this.report().id.replace(/-round-\d+$/, ''));

  constructor() {
    effect(() => {
      const report = this.report();
      const words = this.language.words();
      const path = reportPath(report.id, words.slug);
      this.seo.apply({
        path,
        translatedPath: `/reports/${report.id}`,
        translatedIn: STORY_SLUGS,
        locale: words.locale,
        title: report.headline,
        description: report.lede,
        published: report.date ?? undefined,
        updated: report.date ?? undefined,
        crumbs: [{ label: words.app['today'], path: listPath(words.slug) }],
        entities: [
          {
            '@type': 'Article',
            '@id': `${url(path)}#article`,
            headline: report.headline,
            description: report.lede,
            ...(report.date ? { datePublished: report.date, dateModified: report.date } : {}),
            mainEntityOfPage: { '@id': `${url(path)}#webpage` },
            author: { '@id': url('/#organization') },
            publisher: { '@id': url('/#organization') },
            image: url('/og.jpg'),
            inLanguage: words.locale.tag,
            about: {
              '@type': 'SportsEvent',
              name: report.event.name,
              sport: 'Chess',
              ...(report.event.dates ? { startDate: report.event.dates[0], endDate: report.event.dates[1] } : {}),
              ...(report.event.location ? { location: { '@type': 'Place', name: report.event.location } } : {}),
              ...(report.event.website ? { url: report.event.website } : {}),
            },
          },
        ],
      });
    });
  }
}
