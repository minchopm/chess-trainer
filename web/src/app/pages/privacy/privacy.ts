import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';

import { Seo } from '../../core/seo';
import { SITE } from '../../core/site';
import { PageHead } from '../../shared/page-head/page-head';

@Component({
  selector: 'bp-privacy',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, PageHead],
  templateUrl: './privacy.html',
  styleUrl: './privacy.scss',
})
export class Privacy {
  protected readonly site = SITE;

  constructor() {
    inject(Seo).apply({
      path: '/privacy',
      title: 'Privacy Policy',
      updated: '2026-08-19',
      description:
        'Brass Pawn collects nothing. No analytics, no advertising, no third-party tracking, no account and no server. The full privacy policy, in plain words.',
    });
  }
}
