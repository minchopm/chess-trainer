import { ChangeDetectionStrategy, Component, effect, inject, input } from '@angular/core';

import { Seo } from '../../core/seo';
import { url } from '../../core/site';
import type { Story } from './feed/types';
import { StoryView } from './story-view';

/**
 * A story prerendered at the last deploy: /today/<id>.
 *
 * The page a search lands on, so everything a reader wants from it is in the
 * prerendered HTML. The app is offered as the next step rather than the price
 * of reading — replaying and playing on is what it adds, and a page that hides
 * the moves to sell that is a page nobody links to.
 */
@Component({
  selector: 'bp-story',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [StoryView],
  template: `<bp-story-view [story]="story()" />`,
})
export class StoryPage {
  /** From the route's resolver: this story, loaded on its own. */
  readonly story = input.required<Story>();

  private readonly seo = inject(Seo);

  constructor() {
    effect(() => {
      const story = this.story();
      const path = `/today/${story.id}`;
      this.seo.apply({
        path,
        title: story.headline,
        description: story.lede,
        published: story.date,
        updated: story.date,
        appArgument: `brasspawn://today/${story.id}`,
        crumbs: [{ label: 'Today', path: '/today' }],
        entities: [
          {
            '@type': 'Article',
            '@id': `${url(path)}#article`,
            headline: story.headline,
            description: story.lede,
            datePublished: story.date,
            dateModified: story.date,
            mainEntityOfPage: { '@id': `${url(path)}#webpage` },
            author: { '@id': url('/#organization') },
            publisher: { '@id': url('/#organization') },
            image: url('/og.jpg'),
            inLanguage: 'en',
            about: {
              '@type': 'SportsEvent',
              name: story.event.name,
              sport: 'Chess',
              ...(story.event.location ? { location: { '@type': 'Place', name: story.event.location } } : {}),
            },
            mentions: [story.white, story.black].map((p) => ({ '@type': 'Person', name: p.name })),
          },
        ],
      });
    });
  }
}
