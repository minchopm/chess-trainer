import { ChangeDetectionStrategy, Component, inject, computed, input, effect } from '@angular/core';
import { RouterLink } from '@angular/router';

import { Reveal } from '../../core/reveal';
import { Seo } from '../../core/seo';
import { CurrentLocale } from '../../i18n/current';
import type { Pages } from '../../i18n/pages/types';
import { LIBRARY, MODES, SITE } from '../../core/site';
import { PageHead } from '../../shared/page-head/page-head';

@Component({
  selector: 'bp-training',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, PageHead, Reveal],
  templateUrl: './training.html',
  styleUrl: './training.scss',
})
export class Training {
  /** Resolved by the router before the page renders. See app.routes.ts. */
  readonly pages = input.required<Pages>();
  /**
   * Which language this page is in.
   *
   * From CurrentLocale rather than a route input: that service already derives
   * it from the address, is seeded from `location.pathname` so it is right on
   * the first frame, and does not depend on an input default having been
   * evaluated before the effect below first runs — which it is not.
   */
  private readonly locale = inject(CurrentLocale).locale;

  protected readonly c = computed(() => this.pages().training);

  /** Slug, act numeral and the stat's figure are structure; the words are not. */
  protected readonly modes = computed(() =>
    MODES.map((mode, i) => {
      const words = this.c().modes[i];
      // `stat` means two things: a figure in MODES and its label in the copy.
      // Spreading one over the other silently replaced an object with a string.
      return {
        slug: mode.slug,
        act: mode.act,
        statValue: mode.stat?.value,
        statLabel: words.stat,
        title: words.title,
        lede: words.lede,
        body: words.body,
        free: words.free,
      };
    }),
  );

  /** The step numbers stay in code; only the sentences are translated. */
  protected readonly pipelineSteps = computed(() =>
    this.c().pipeline.steps.map((step, i) => ({ ...step, step: String(i + 1).padStart(2, '0') })),
  );

  /** The library's two figures belong to the data, not to thirty-two translations. */
  protected readonly limits = computed(() =>
    this.c().limits.items.map((item) => ({
      ...item,
      body: item.body
        .replace('{lichess}', LIBRARY.tacticsLichess.toLocaleString('en-US'))
        .replace('{mined}', String(LIBRARY.tacticsMined)),
    })),
  );

  protected readonly site = SITE;
  protected readonly library = LIBRARY;

  /** How a mined puzzle gets from "the engine played something" to shipping. */

  constructor() {
    const seo = inject(Seo);
    // In an effect because the language arrives as an input, and the title, the
    // description, the canonical and the `lang` attribute all follow it.
    effect(() => {
      const locale = this.locale();
      const meta = this.c().meta;
      seo.apply({
        path: locale.slug === 'en' ? '/training' : `/${locale.slug}/training`,
        translatedPath: '/training',
        locale,
        title: meta.title,
        description: meta.description,
        updated: '2026-08-24',
      });
    });
  }
}
