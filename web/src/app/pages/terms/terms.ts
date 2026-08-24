import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';

import { Seo } from '../../core/seo';
import { PRICING, SITE } from '../../core/site';
import { PageHead } from '../../shared/page-head/page-head';

@Component({
  selector: 'bp-terms',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, PageHead],
  templateUrl: './terms.html',
  styleUrl: '../privacy/privacy.scss',
})
export class Terms {
  protected readonly site = SITE;
  protected readonly pricing = PRICING;

  constructor() {
    inject(Seo).apply({
      path: '/terms',
      title: 'Terms of Service',
      updated: '2026-08-19',
      description:
        'The terms of use and end user licence agreement for Brass Pawn, including the App Store minimum terms, subscription terms, and how they sit alongside the GNU General Public License v3.',
    });
  }
}
