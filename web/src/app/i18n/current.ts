import { DOCUMENT, Injectable, computed, inject } from '@angular/core';
import { NavigationEnd, Router } from '@angular/router';
import { toSignal } from '@angular/core/rxjs-interop';
import { filter, map, startWith } from 'rxjs';

import { DEFAULT_LOCALE, type Locale, bySlug } from './locales';

/**
 * Which language the page being read is written in.
 *
 * Derived from the address rather than announced by the page, and seeded from
 * `location.pathname` rather than from `Router.url`. That second detail is not
 * fussiness: before the router's first navigation resolves, `Router.url` is
 * `/`, and the browser's first render during hydration happens before it
 * resolves. A header that renders the English links for one frame and then
 * swaps them is not a flicker — Angular hydrates against the markup the server
 * wrote, finds a different set of nodes, and leaves both sets in the document.
 *
 * `location.pathname` is already correct on that first frame, in the
 * prerenderer and in the browser alike, which is the whole requirement.
 */
@Injectable({ providedIn: 'root' })
export class CurrentLocale {
  private readonly doc = inject(DOCUMENT);
  private readonly router = inject(Router);

  private readonly path = toSignal(
    this.router.events.pipe(
      filter((event): event is NavigationEnd => event instanceof NavigationEnd),
      map((event) => event.urlAfterRedirects),
      startWith(this.here()),
    ),
    { initialValue: this.here() },
  );

  /** The locale, or English — which is the site root and every essay on it. */
  readonly locale = computed<Locale>(() => this.match() ?? DEFAULT_LOCALE);

  /** Null on the English pages, so a caller can tell "English" from "not localised". */
  readonly localised = computed<Locale | null>(() => {
    const locale = this.match();
    return locale && locale.slug !== 'en' ? locale : null;
  });

  private match(): Locale | undefined {
    const first = this.path().split(/[?#]/)[0].split('/').filter(Boolean)[0];
    return first ? bySlug(first) : undefined;
  }

  private here(): string {
    return this.doc.location?.pathname || this.router.url;
  }
}
