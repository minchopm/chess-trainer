import { DOCUMENT, Injectable, inject } from '@angular/core';
import { Meta, Title } from '@angular/platform-browser';

import { DEFAULT_LOCALE, LOCALES as LANGUAGES, type Locale, localePath } from '../i18n/locales';
import { LIBRARY, LOCALES, PRICING, SITE, url } from './site';

/** One step in the trail, in the order a reader would walk it. */
export interface Crumb {
  readonly label: string;
  readonly path: string;
}

export interface PageMeta {
  readonly title: string;
  readonly description: string;
  /** Route path, e.g. '/privacy'. '/' for the home page. */
  readonly path: string;
  /** The trail above this page. The home page and the page itself are added. */
  readonly crumbs?: readonly Crumb[];
  /** ISO date this page's content last changed materially. */
  readonly updated?: string;
  /** Extra entities to append to the graph — an FAQPage, say. */
  readonly entities?: readonly Record<string, unknown>[];
  /**
   * The language this page is written in. Sets `<html lang>` and `dir`, the
   * Open Graph locale and `inLanguage` throughout the graph.
   */
  readonly locale?: Locale;
  /**
   * True on the pages that exist in every language, which are the only pages
   * allowed to declare alternates.
   *
   * hreflang describes translations of the same page. The essays — the licence
   * notes, the glossary, the two legal pages — exist in English and nowhere
   * else, and claiming a German alternate for a page that has none is how a
   * site teaches a search engine to distrust the rest of its annotations.
   */
  readonly translated?: boolean;
}

/**
 * Titles, descriptions, canonical links and structured data.
 *
 * Two things here are worth knowing.
 *
 * The site is prerendered, so all of this ends up in the static HTML a crawler
 * downloads rather than being assembled by a script it may or may not run.
 *
 * And the structured data is one connected `@graph` rather than a pile of
 * separate blocks. Search engines resolve `@id` references, so saying the
 * publisher once and pointing at it from the site, the app and every page
 * describes an entity they can actually reconcile — where four disconnected
 * objects that happen to share a name do not.
 */
@Injectable({ providedIn: 'root' })
export class Seo {
  private readonly doc = inject(DOCUMENT);
  private readonly title = inject(Title);
  private readonly meta = inject(Meta);

  apply(page: PageMeta): void {
    const locale = page.locale ?? DEFAULT_LOCALE;
    const full = this.headline(page);
    const canonical = url(page.path);

    this.title.setTitle(full);

    // The document's own language, which is what a screen reader picks a voice
    // from and what a browser offers to translate against. Set on every page,
    // not only the localised ones, so that walking from /ja to /privacy leaves
    // English announced as English.
    const root = this.doc.documentElement;
    root.setAttribute('lang', locale.tag);
    root.setAttribute('dir', locale.dir);

    for (const [key, content] of Object.entries(this.tags(page, full, canonical))) {
      if (!content) continue;
      this.meta.updateTag(
        key.startsWith('og:') ? { property: key, content } : { name: key, content },
        key.startsWith('og:') ? `property="${key}"` : `name="${key}"`,
      );
    }

    this.setLink('canonical', canonical);
    this.setAlternates(page);
    this.setJsonLd(this.graph(page, full, canonical, locale));
  }

  /**
   * The title tag.
   *
   * On a localised page the product name comes second: somebody searching in
   * Japanese is searching for the category, and a title that opens with two
   * English words they do not recognise loses the click before the sentence
   * that would have won it.
   */
  private headline(page: PageMeta): string {
    if (page.path === '/') return `${SITE.name} — ${SITE.category}`;
    if (page.translated) return `${SITE.name} — ${page.title}`;
    return `${page.title} — ${SITE.name}`;
  }

  /**
   * `rel="alternate"` for every language, plus `x-default`.
   *
   * Every page in the set names every other one including itself — a set where
   * the pages disagree about who is in it is discarded whole, so it is emitted
   * from one list rather than assembled per page.
   */
  private setAlternates(page: PageMeta): void {
    for (const link of Array.from(
      this.doc.head.querySelectorAll('link[rel="alternate"][hreflang]'),
    )) {
      link.remove();
    }
    if (!page.translated) return;

    for (const locale of LANGUAGES) {
      this.addLink('alternate', url(localePath(locale)), locale.tag);
    }
    // Not a language: it is what to serve somebody whose own language is not
    // among the thirty-one, and English is that.
    this.addLink('alternate', url('/'), 'x-default');
  }

  private tags(page: PageMeta, full: string, canonical: string): Record<string, string> {
    const locale = page.locale ?? DEFAULT_LOCALE;
    return {
      description: page.description,

      // Without max-image-preview:large a result gets a thumbnail rather than
      // the wide card, and max-snippet:-1 lets the description come from the
      // page instead of being truncated to a default.
      robots: 'index, follow, max-snippet:-1, max-image-preview:large, max-video-preview:-1',

      'og:type': 'website',
      'og:site_name': SITE.name,
      'og:locale': locale.tag.replace('-', '_'),
      'og:title': full,
      'og:description': page.description,
      'og:url': canonical,
      'og:image': url('/og.png'),
      'og:image:width': '1200',
      'og:image:height': '630',
      'og:image:type': 'image/png',
      'og:image:alt': `${SITE.name} — ${SITE.tagline}`,

      'twitter:card': 'summary_large_image',
      'twitter:title': full,
      'twitter:description': page.description,
      'twitter:image': url('/og.png'),
      'twitter:image:alt': `${SITE.name} — ${SITE.tagline}`,

      // Safari's smart app banner. Emitted only once there is a real listing to
      // point at — a banner to a dead id is worse than no banner.
      ...(SITE.appStoreId ? { 'apple-itunes-app': `app-id=${SITE.appStoreId}` } : {}),
    };
  }

  /** The publisher, the site and the app — said once, referenced everywhere. */
  private graph(
    page: PageMeta,
    full: string,
    canonical: string,
    locale: Locale,
  ): Record<string, unknown> {
    const org = {
      '@type': 'Organization',
      '@id': url('/#organization'),
      name: 'Arte Soft',
      alternateName: SITE.publisher,
      url: url('/'),
      logo: {
        '@type': 'ImageObject',
        '@id': url('/#logo'),
        url: url('/icon-512.png'),
        width: 512,
        height: 512,
        caption: SITE.name,
      },
      image: { '@id': url('/#logo') },
      email: SITE.contactEmail,
      sameAs: [SITE.repo],
      founder: { '@type': 'Person', name: SITE.publisher },
    };

    const website = {
      '@type': 'WebSite',
      '@id': url('/#website'),
      url: url('/'),
      name: SITE.name,
      description: SITE.tagline,
      publisher: { '@id': url('/#organization') },
      inLanguage: LOCALES,
    };

    const app = {
      '@type': 'MobileApplication',
      '@id': url('/#app'),
      name: SITE.name,
      applicationCategory: 'GameApplication',
      applicationSubCategory: 'Chess',
      operatingSystem: SITE.minimumOs,
      softwareVersion: SITE.version,
      datePublished: SITE.published,
      url: url('/'),
      ...(SITE.appStoreId ? { installUrl: SITE.appStore, downloadUrl: SITE.appStore } : {}),
      description:
        'A chess training app for iPhone and iPad: tactics, positional judgement, endgame ' +
        'technique, Rush, Guess the Elo, coached play and online games, with Stockfish running ' +
        'on the device. No account, no analytics and no advertising.',
      inLanguage: LOCALES,
      license: 'https://www.gnu.org/licenses/gpl-3.0.html',
      author: { '@id': url('/#organization') },
      publisher: { '@id': url('/#organization') },
      image: { '@id': url('/#logo') },
      featureList: [
        `${LIBRARY.tactics.toLocaleString('en-US')} tactics puzzles rated ${LIBRARY.ratingFloor} to ${LIBRARY.ratingCeiling}`,
        `${LIBRARY.positional} positional judgement exercises`,
        `${LIBRARY.endgames} engine-verified endgame drills`,
        'Rush — a timed puzzle run',
        `Guess the Elo — ${LIBRARY.games.toLocaleString('en-US')} real rated games to judge`,
        'Play and coach: every move graded while the game is going',
        'Online play over Game Center, with no engine assistance',
        'Stockfish 18 running on the device, offline',
        'Spaced repetition and per-discipline ratings',
        `Translated into ${LIBRARY.locales} languages`,
      ],
      offers: [
        {
          '@type': 'Offer',
          name: 'Free',
          price: '0',
          priceCurrency: 'USD',
          availability: 'https://schema.org/InStock',
          description:
            'Unlimited play against the engine and against a person, plus a daily allowance of ' +
            'puzzles, drills and exercises.',
        },
        {
          '@type': 'Offer',
          name: 'Brass Pawn Pro — monthly',
          price: PRICING.monthly.replace('$', ''),
          priceCurrency: 'USD',
          availability: 'https://schema.org/InStock',
        },
        {
          '@type': 'Offer',
          name: 'Brass Pawn Pro — one-off unlock',
          price: PRICING.lifetime.replace('$', ''),
          priceCurrency: 'USD',
          availability: 'https://schema.org/InStock',
        },
      ],
    };

    const webPage: Record<string, unknown> = {
      '@type': 'WebPage',
      '@id': `${canonical}#webpage`,
      url: canonical,
      name: full,
      description: page.description,
      isPartOf: { '@id': url('/#website') },
      about: { '@id': url('/#app') },
      primaryImageOfPage: { '@id': url('/#logo') },
      inLanguage: locale.tag,
      datePublished: SITE.published,
      dateModified: page.updated ?? SITE.published,
    };

    // A single-item trail is just the home page pointing at itself, which is
    // noise; Google ignores it and it makes the graph harder to read.
    //
    // A localised page has no trail either, for the same reason: /de is not a
    // page below the English home, it is the home page in German. Saying
    // "Home › ein Schachtrainer für iPhone und iPad" would describe a hierarchy
    // that does not exist and would put a category description where a
    // breadcrumb label belongs.
    const trail = page.translated ? [] : [{ label: 'Home', path: '/' }, ...(page.crumbs ?? [])];
    if (trail.length && page.path !== '/') trail.push({ label: page.title, path: page.path });

    if (trail.length > 1) {
      webPage['breadcrumb'] = { '@id': `${canonical}#breadcrumb` };
    }

    return {
      '@context': 'https://schema.org',
      '@graph': [
        org,
        website,
        app,
        webPage,
        ...(trail.length > 1
          ? [
              {
                '@type': 'BreadcrumbList',
                '@id': `${canonical}#breadcrumb`,
                itemListElement: trail.map((crumb, i) => ({
                  '@type': 'ListItem',
                  position: i + 1,
                  name: crumb.label,
                  item: url(crumb.path),
                })),
              },
            ]
          : []),
        ...(page.entities ?? []),
      ],
    };
  }

  /** Appends a link. Used for the alternates, which are a set rather than one. */
  private addLink(rel: string, href: string, hreflang?: string): void {
    const link = this.doc.createElement('link');
    link.setAttribute('rel', rel);
    link.setAttribute('href', href);
    if (hreflang) link.setAttribute('hreflang', hreflang);
    this.doc.head.appendChild(link);
  }

  private setLink(rel: string, href: string): void {
    let link = this.doc.head.querySelector<HTMLLinkElement>(`link[rel="${rel}"]:not([hreflang])`);
    if (!link) {
      link = this.doc.createElement('link');
      link.setAttribute('rel', rel);
      this.doc.head.appendChild(link);
    }
    link.setAttribute('href', href);
  }

  private setJsonLd(data: Record<string, unknown>): void {
    const id = 'bp-jsonld';
    this.doc.getElementById(id)?.remove();

    const script = this.doc.createElement('script');
    script.id = id;
    script.type = 'application/ld+json';
    // `<` cannot appear raw inside a script element without ending it early.
    script.textContent = JSON.stringify(data).replace(/</g, '\\u003c');
    this.doc.head.appendChild(script);
  }
}
