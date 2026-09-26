import { afterNextRender, ChangeDetectionStrategy, Component, computed, signal } from '@angular/core';
import { RouterLink } from '@angular/router';

import { Reveal } from '../../core/reveal';
import { FEED } from './feed';
import type { StorySummary } from './feed/types';
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
            <p class="slug">Today · on the top boards</p>
            <h2>The day’s games, and where they turned.</h2>
            <p class="lede measure dim">
              The finished games from the biggest events, each with the move Stockfish says decided it.
              Open one in Brass Pawn to replay it and take the position over.
            </p>
          </header>
          <ol class="stories">
            @for (story of stories(); track story.id; let i = $index) {
              <li [ctReveal]="i * 70"><bp-story-card [story]="story" /></li>
            }
          </ol>
          <p class="more mono" ctReveal><a routerLink="/today">All the stories →</a></p>
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
  private readonly live = signal<StorySummary[]>([]);

  protected readonly stories = computed(() =>
    [...this.live(), ...FEED].sort((a, b) => b.date.localeCompare(a.date)).slice(0, SHOWN),
  );

  constructor() {
    afterNextRender(async () => this.live.set(await liveStories()));
  }
}
