import { ChangeDetectionStrategy, Component, effect, inject, input } from '@angular/core';

import { Seo } from '../../core/seo';
import { url } from '../../core/site';
import type { Story, StorySummary } from './feed/types';
import { listPath, STORY_SLUGS, storyPath, TodayLanguage } from './i18n';
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
  template: `<bp-story-view [story]="story()" [feed]="feed()" />`,
})
export class StoryPage {
  /** From the route's resolver: this story, loaded on its own. */
  readonly story = input.required<Story>();
  /** From the route, on the pages in another language: that language's list, for the neighbours. */
  readonly feed = input<readonly StorySummary[] | undefined>(undefined);

  private readonly seo = inject(Seo);
  private readonly language = inject(TodayLanguage);

  constructor() {
    effect(() => {
      const story = this.story();
      const words = this.language.words();
      // Its own address in the reader's language, and the same story's pages
      // in every other language named as its translations.
      const path = storyPath(story.id, words.slug);
      this.seo.apply({
        path,
        translatedPath: `/today/${story.id}`,
        translatedIn: STORY_SLUGS,
        locale: words.locale,
        title: story.headline,
        description: story.lede,
        published: story.date,
        updated: story.date,
        appArgument: `brasspawn://today/${story.id}`,
        crumbs: [{ label: words.app['today'], path: listPath(words.slug) }],
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
            inLanguage: words.locale.tag,
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
