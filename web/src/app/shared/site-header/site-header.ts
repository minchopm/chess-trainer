import {
  ChangeDetectionStrategy,
  Component,
  afterNextRender,
  computed,
  inject,
  signal,
} from '@angular/core';
import { RouterLink, RouterLinkActive } from '@angular/router';

import { SITE } from '../../core/site';
import { CurrentLocale } from '../../i18n/current';
import { LanguagePicker } from '../language-picker/language-picker';

/**
 * The title bar. Transparent over the opening shot, then it gains a ground as
 * soon as there is anything behind it to read against.
 */
@Component({
  selector: 'bp-site-header',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, RouterLinkActive, LanguagePicker],
  templateUrl: './site-header.html',
  styleUrl: './site-header.scss',
  host: {
    '[class.is-grounded]': 'grounded()',
    '[class.is-open]': 'open()',
  },
})
export class SiteHeader {
  protected readonly site = SITE;
  protected readonly grounded = signal(false);
  protected readonly open = signal(false);

  private readonly localised = inject(CurrentLocale).localised;

  private readonly english = [
    { path: '/training', label: 'Training' },
    { path: '/tactics', label: 'Tactics' },
    { path: '/engine', label: 'The engine' },
    { path: '/pricing', label: 'Pricing' },
    { path: '/privacy', label: 'Privacy' },
  ] as const;

  /**
   * What the bar offers.
   *
   * On the English site: the five essays. On a localised page: the four parts
   * of that page, named in its own language — because the essays are in English
   * and a bar full of unmarked English links on a Japanese page tells a reader
   * nothing about where they lead. The English pages are still one click away;
   * they are at the foot of the page, labelled as English.
   */
  protected readonly links = computed(() => {
    const locale = this.localised();
    if (!locale) return this.english;

    // Fragment ids, not `#`-prefixed hrefs. A bare `href="#see"` resolves
    // against `<base href="/">` rather than against the current URL, so on a
    // localised page it would send the reader to the English home page with a
    // fragment nothing on it matches.
    const { nav } = locale;
    return [
      { path: 'see', label: nav.film },
      { path: 'screens', label: nav.screens },
      { path: 'price', label: nav.price },
      { path: 'questions', label: nav.questions },
    ];
  });

  protected readonly cta = computed(() => {
    const nav = this.localised()?.nav;
    if (!nav) return SITE.appStoreLive ? 'App\u00a0Store' : 'Coming\u00a0soon';
    return SITE.appStoreLive ? nav.download : nav.soon;
  });

  /** True when the links are anchors on the page already open rather than routes. */
  protected readonly inPage = computed(() => this.localised() !== null);

  constructor() {
    afterNextRender(() => {
      const onScroll = () => this.grounded.set(window.scrollY > 64);
      onScroll();
      window.addEventListener('scroll', onScroll, { passive: true });
    });
  }

  protected toggle(): void {
    this.open.update((v) => !v);
  }

  protected close(): void {
    this.open.set(false);
  }
}
