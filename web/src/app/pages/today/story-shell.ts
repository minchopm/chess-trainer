import { afterNextRender, ChangeDetectionStrategy, Component, inject, input, signal } from '@angular/core';
import { Router, RouterLink } from '@angular/router';

import { Seo } from '../../core/seo';
import { BUILT, hasPage } from './live';
import type { Story } from './feed/types';
import { StoryView } from './story-view';

/**
 * The address a story had before it had a page: /today/story?id=<id>.
 *
 * The collector now writes every new story's page as it writes the story, so
 * this is for links made before it did, and for a story whose page failed to
 * render and waits for the next run. One with a page is sent to it; one
 * without is drawn here, in the browser, from the file the app reads. It asks
 * search engines not to index it: the story's own address is the one to rank.
 */
@Component({
  selector: 'bp-story-shell',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, StoryView],
  template: `
    @if (story(); as story) {
      <bp-story-view [story]="story" />
    } @else {
      <div class="page shell">
        <p class="mono faint">{{ missing() ? 'That story is not in the feed.' : 'Loading the story…' }}</p>
        <a class="mono" routerLink="/today">All stories →</a>
      </div>
    }
  `,
  styles: `
    .shell {
      min-height: 60vh;
      padding-top: calc(4.25rem + clamp(3.5rem, 10vh, 7rem));
    }
  `,
})
export class StoryShell {
  /** From the query string, through the router's input binding. */
  readonly id = input<string>();

  protected readonly story = signal<Story | null>(null);
  protected readonly missing = signal(false);

  constructor() {
    inject(Seo).apply({
      path: '/today/story',
      title: 'Today',
      description: 'A story from the daily feed of top chess games.',
      noindex: true,
    });
    const router = inject(Router);
    afterNextRender(async () => {
      const id = this.id();
      if (!id || !/^[a-z0-9-]+$/.test(id)) {
        this.missing.set(true);
        return;
      }
      // Built since the link was shared: its own page, which is the one to
      // read and the one a search engine knows.
      if (BUILT.has(id)) {
        await router.navigateByUrl(`/today/${id}`, { replaceUrl: true });
        return;
      }
      try {
        const response = await fetch(`/media/feed/v1/stories/${id}.json`);
        const story = response.ok ? await response.json() : null;
        // Given its own page since the link was made: that page, which has
        // the replay and is the address to keep.
        if (story && hasPage(story)) {
          location.replace(`/today/${id}`);
          return;
        }
        if (story) {
          this.story.set(story);
          document.title = `${story.headline} — Brass Pawn`;
        } else {
          this.missing.set(true);
        }
      } catch {
        this.missing.set(true);
      }
    });
  }
}
