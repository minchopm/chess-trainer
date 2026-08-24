import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';

import { SITE } from '../../core/site';
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
  protected readonly site = SITE;
  protected readonly year = SITE.copyrightYear;
  protected readonly locales = LOCALES;

  protected readonly columns = [
    {
      heading: 'The app',
      links: [
        { path: '/training', label: 'Training' },
        { path: '/engine', label: 'The engine' },
        { path: '/pricing', label: 'Pricing' },
        { path: '/support', label: 'Support & FAQ' },
      ],
    },
    {
      heading: 'Chess',
      links: [
        { path: '/tactics', label: 'The twenty motifs' },
        { path: '/watch', label: 'Nine hundred games' },
        { path: '/ratings', label: 'What a rating measures' },
      ],
    },
    {
      heading: 'Legal',
      links: [
        { path: '/privacy', label: 'Privacy Policy' },
        { path: '/terms', label: 'Terms of Service' },
        { path: '/licences', label: 'Licences & attribution' },
      ],
    },
  ] as const;
}
