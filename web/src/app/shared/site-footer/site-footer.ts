import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { RouterLink } from '@angular/router';

import { SITE } from '../../core/site';
import { CurrentLocale } from '../../i18n/current';
import { LOCALES } from '../../i18n/locales';

/** End credits. Everything legal is one click from here, on every page. */
@Component({
  selector: 'bp-site-footer',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  templateUrl: './site-footer.html',
  styleUrl: './site-footer.scss',
})
export class SiteFooter {
  private readonly current = inject(CurrentLocale);

  protected readonly site = SITE;
  protected readonly year = SITE.copyrightYear;
  protected readonly locales = LOCALES;

  /**
   * The footer's own words, in the language of the page.
   *
   * The link labels below stay English on purpose: they name essays that exist
   * only in English, and each one is marked as leaving the language behind —
   * the same treatment the localised home page already gives them.
   */
  protected readonly chrome = computed(() => this.current.locale().chrome);
  protected readonly localised = this.current.localised;
  protected readonly lede = computed(() => this.current.locale().chrome);

  protected readonly columns = [
    {
      key: 'colApp' as const,
      heading: 'The app',
      links: [
        { path: '/training', label: 'Training' },
        { path: '/engine', label: 'The engine' },
        { path: '/pricing', label: 'Pricing' },
        { path: '/support', label: 'Support & FAQ' },
      ],
    },
    {
      key: 'colChess' as const,
      heading: 'Chess',
      links: [
        { path: '/tactics', label: 'The twenty motifs' },
        { path: '/watch', label: 'Nine hundred games' },
        { path: '/ratings', label: 'What a rating measures' },
      ],
    },
    {
      key: 'colLegal' as const,
      heading: 'Legal',
      links: [
        { path: '/privacy', label: 'Privacy Policy' },
        { path: '/terms', label: 'Terms of Service' },
        { path: '/licences', label: 'Licences & attribution' },
      ],
    },
  ] as const;
}
