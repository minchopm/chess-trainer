import { afterNextRender, ChangeDetectionStrategy, Component, computed, inject, input, signal } from '@angular/core';
import { RouterLink } from '@angular/router';

import { Reveal } from '../../core/reveal';
import { FEED } from './feed';
import type { StorySummary } from './feed/types';
import { feedFolder, listPath, TodayLanguage } from './i18n';
import { liveStories } from './live';
import { StoryCard } from './story-card';

/** How many stories the home page shows. The rest are on /today. */
const SHOWN = 3;

/**
 * The newest stories from the daily feed, on the home page.
 *
 * Nothing at all when there are none — an empty "Today" on the first page a
 * visitor sees says the feature is broken, which is worse than not mentioning
 * it. The prerendered stories are whatever the last deploy had; newer ones
 * arrive from the live feed once the page is in the browser.
 */
@Component({
  selector: 'bp-today-strip',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, Reveal, StoryCard],
  template: `
    @if (stories().length) {
      <section class="strip" id="today">
        <div class="page">
          <header class="section-head" ctReveal>
            <p class="slug">{{ w().stripSlug }}</p>
            <h2>{{ w().stripTitle }}</h2>
            <p class="lede measure dim">{{ w().stripLede }}</p>
          </header>
          <ol class="stories">
            @for (story of stories(); track story.id; let i = $index) {
              <li [ctReveal]="i * 70"><bp-story-card [story]="story" /></li>
            }
          </ol>
          <p class="more mono" ctReveal><a [routerLink]="list()">{{ w().allStories }}</a></p>
        </div>
      </section>
    }
  `,
  styles: `
    .strip { padding: var(--rhythm) 0; border-top: 1px solid var(--rule-soft); }
    .stories {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(min(100%, 22rem), 1fr));
      gap: clamp(1rem, 2.5vw, 1.75rem);
      list-style: none;
      margin: 0 0 2rem;
      padding: 0;
    }
    .more { margin: 0; }
  `,
})
export class TodayStrip {
  /** A home page in another language passes its language's list. */
  readonly feed = input<readonly StorySummary[] | undefined>(undefined);

  private readonly language = inject(TodayLanguage);
  protected readonly w = this.language.words;
  protected readonly list = computed(() => listPath(this.w().slug));
  private readonly live = signal<StorySummary[]>([]);

  protected readonly stories = computed(() =>
    [...this.live(), ...(this.feed() ?? FEED)].sort((a, b) => b.date.localeCompare(a.date)).slice(0, SHOWN),
  );

  constructor() {
    afterNextRender(async () => {
      const own = new Set((this.feed() ?? FEED).map((story) => story.id));
      this.live.set(await liveStories(feedFolder(this.w().slug), own));
    });
  }
}
