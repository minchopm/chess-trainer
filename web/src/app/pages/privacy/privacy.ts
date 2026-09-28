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
      updated: '2026-09-28',
      description:
        'Brass Pawn collects nothing outside online play, and there only who is online. No analytics, no advertising, no third-party tracking and no account. The full privacy policy, in plain words.',
    });
  }
}
