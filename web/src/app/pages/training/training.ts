import { ChangeDetectionStrategy, Component, inject, computed, input } from '@angular/core';
import { RouterLink } from '@angular/router';

import { Reveal } from '../../core/reveal';
import { Seo } from '../../core/seo';
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
    inject(Seo).apply({
      path: '/training',
      title: 'The training',
      updated: '2026-08-24',
      description:
        'Eight modes: tactics, positional judgement, endgames, Rush, Guess the Elo, Watch, coached play and online. How the puzzles are mined, and what is free.',
    });
  }
}
