import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';

import { Reveal } from '../../core/reveal';
import { Seo } from '../../core/seo';
import { ENGINES, SITE } from '../../core/site';
import { PageHead } from '../../shared/page-head/page-head';

@Component({
  selector: 'bp-engine',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, PageHead, Reveal],
  templateUrl: './engine.html',
  styleUrl: './engine.scss',
})
export class EnginePage {
  protected readonly site = SITE;
  protected readonly engines = ENGINES;

  constructor() {
    inject(Seo).apply({
      path: '/engine',
      title: 'The engine',
      updated: '2026-08-24',
      description:
        'Stockfish 18 and Reckless, both on the device, and you choose which one plays. Why move grading uses win probability rather than centipawns.',
    });
  }
}
