import { isPlatformBrowser } from '@angular/common';
import { inject, makeStateKey, PLATFORM_ID, REQUEST_CONTEXT, TransferState } from '@angular/core';
import { ActivatedRouteSnapshot, RedirectCommand, Router } from '@angular/router';

import type { Locale } from '../../i18n/locales';
import { feedFolder } from '../today/i18n/slugs';
import type { Report } from './types';

/** What the collector hands the renderer with a report's page. */
export interface ReportRenderContext {
  readonly report: Report;
}

/**
 * The report for /reports/<id>, in the page's language.
 *
 * Every report's page is the collector's to render (scripts/feed/pages.mjs),
 * which hands the report over with the request; the page carries it to the
 * browser in its transfer state, so hydrating it asks for nothing. A link
 * followed inside the site reads the report's own file.
 */
export function resolveReport(route: ActivatedRouteSnapshot): Promise<Report | RedirectCommand> {
  const id = route.paramMap.get('id') ?? '';
  const locale = route.data['locale'] as Locale | undefined;
  const folder = locale ? feedFolder(locale.slug) : null;
  const router = inject(Router);
  const state = inject(TransferState);
  const context = inject(REQUEST_CONTEXT, { optional: true }) as ReportRenderContext | null;
  const browser = isPlatformBrowser(inject(PLATFORM_ID));
  const key = makeStateKey<Report>(`report:${folder ?? 'en'}:${id}`);

  return (async () => {
    if (context?.report?.id === id) {
      state.set(key, context.report);
      return context.report;
    }
    const carried = state.get(key, null);
    if (carried) return carried;

    if (browser && /^[a-z0-9-]{1,120}$/.test(id)) {
      try {
        const response = await fetch(`/media/feed/v1/${folder ? `${folder}/` : ''}reports/${id}.json`);
        if (response.ok) return (await response.json()) as Report;
      } catch {
        // The 404 below.
      }
    }
    return new RedirectCommand(router.parseUrl('/404'));
  })();
}
