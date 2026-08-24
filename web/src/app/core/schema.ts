import { SITE, url } from './site';

/**
 * The two entities that more than one page describes.
 *
 * Both were written for the localised pages and then wanted by the English
 * home page, which shows the same four questions and the same three films. A
 * second copy of either would be a second thing to keep true.
 */

export interface Answered {
  readonly q: string;
  readonly a: string;
}

/**
 * The questions on the page, marked up as questions.
 *
 * Worth the bytes because an answer engine quoting a product is going to quote
 * something; a page that states its own answers in a form meant to be lifted
 * gets to choose which sentences those are.
 */
export const faqPage = (path: string, locale: string, items: readonly Answered[]) => ({
  '@type': 'FAQPage',
  '@id': `${url(path)}#faq`,
  inLanguage: locale,
  mainEntity: items.map(({ q, a }) => ({
    '@type': 'Question',
    name: q,
    acceptedAnswer: { '@type': 'Answer', text: a },
  })),
});

export interface Film {
  readonly clip: string;
  readonly name: string;
  readonly description: string;
}

/**
 * The three films, declared as what they are.
 *
 * A VideoObject is one of the few kinds of structured data that changes the
 * shape of a result rather than decorating it — and these genuinely are a
 * spoken description of the product, in the language of whoever is reading.
 */
export const filmList = (path: string, slug: string, locale: string, films: readonly Film[]) => ({
  '@type': 'ItemList',
  '@id': `${url(path)}#films`,
  itemListElement: films.map((film, i) => ({
    '@type': 'ListItem',
    position: i + 1,
    item: {
      '@type': 'VideoObject',
      '@id': `${url(path)}#film-${film.clip}`,
      name: `${SITE.name} — ${film.name}`,
      description: film.description,
      inLanguage: locale,
      uploadDate: SITE.published,
      thumbnailUrl: url(`/media/video/iphone/${slug}/${film.clip}.jpg`),
      contentUrl: url(`/media/video/iphone/${slug}/${film.clip}.mp4`),
      isFamilyFriendly: true,
      about: { '@id': url('/#app') },
    },
  })),
});
