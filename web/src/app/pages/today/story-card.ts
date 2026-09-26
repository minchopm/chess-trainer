import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { RouterLink } from '@angular/router';

import { Diagram } from './diagram';
import type { StorySummary } from './feed/types';
import { storyLink } from './live';
import { occasion, resultText } from './words';

/** One story in a list: its board, where it was played, and what happened. */
@Component({
  selector: 'bp-story-card',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, Diagram],
  template: `
    <a class="story" [routerLink]="link().path" [queryParams]="link().query">
      <bp-diagram
        class="story__board"
        [fen]="story().fen"
        [last]="story().last"
        [flip]="story().result === '0-1'"
        [label]="'The position in ' + story().white.short + '–' + story().black.short"
      />
      <div class="story__words">
        <p class="mono story__occasion">{{ occasion() }}</p>
        <h3>{{ story().headline }}</h3>
        <p class="mono story__players">
          {{ story().white.short }} {{ result() }} {{ story().black.short }}
        </p>
        <p class="dim story__lede">{{ story().lede }}</p>
      </div>
    </a>
  `,
  styles: `
    :host { display: block; height: 100%; }
    .story {
      display: grid;
      grid-template-columns: 7.5rem minmax(0, 1fr);
      gap: 1.1rem;
      align-items: start;
      height: 100%;
      padding: 1rem;
      border: 1px solid var(--rule);
      border-radius: 0.9rem;
      background: linear-gradient(160deg, var(--ink-3), var(--ink-2));
      color: inherit;
      text-decoration: none;
      transition: border-color 0.3s var(--ease), transform 0.3s var(--ease);
    }
    .story:hover, .story:focus-visible { border-color: var(--brass-deep); transform: translateY(-2px); }
    .story__occasion, .story__players {
      font-size: var(--label);
      letter-spacing: 0.14em;
      text-transform: uppercase;
      color: var(--ivory-faint);
      margin: 0;
    }
    h3 { font-size: 1.3rem; line-height: 1.2; margin: 0.45rem 0; }
    .story__players { color: var(--brass); }
    .story__lede {
      font-size: 0.875rem;
      margin: 0.6rem 0 0;
      display: -webkit-box;
      -webkit-line-clamp: 3;
      -webkit-box-orient: vertical;
      overflow: hidden;
    }
    @media (max-width: 30rem) {
      .story { grid-template-columns: 5.75rem minmax(0, 1fr); gap: 0.85rem; }
    }
  `,
})
export class StoryCard {
  readonly story = input.required<StorySummary>();
  protected readonly link = computed(() => storyLink(this.story()));
  protected readonly occasion = computed(() => occasion(this.story()));
  protected readonly result = computed(() => resultText(this.story().result));
}
