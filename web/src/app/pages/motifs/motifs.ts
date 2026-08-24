import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';

import { Reveal } from '../../core/reveal';
import { Seo } from '../../core/seo';
import { LIBRARY, MOTIFS, url } from '../../core/site';
import { PageHead } from '../../shared/page-head/page-head';

/**
 * The tactical vocabulary, defined.
 *
 * It earns its place on a brochure site because it is the vocabulary the app
 * actually tags puzzles with — every entry ends in a real number of positions
 * that turn on it — rather than a glossary bolted on to catch searches.
 */
@Component({
  selector: 'bp-motifs',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, PageHead, Reveal],
  templateUrl: './motifs.html',
  styleUrl: './motifs.scss',
})
export class Motifs {
  protected readonly motifs = MOTIFS;
  protected readonly library = LIBRARY;

  constructor() {
    inject(Seo).apply({
      path: '/tactics',
      title: 'Chess tactics: the twenty motifs',
      description:
        'Fork, pin, skewer, discovered attack, deflection, zwischenzug, zugzwang and the rest — ' +
        'what each tactical motif is, how to spot it, and how many of Brass Pawn’s 14,351 ' +
        'puzzles turn on it.',
      updated: '2026-08-19',
      crumbs: [{ label: 'The training', path: '/training' }],
      entities: [
        {
          '@type': 'DefinedTermSet',
          '@id': url('/tactics#glossary'),
          name: 'Chess tactical motifs',
          description: 'The tactical vocabulary Brass Pawn tags its puzzle library with.',
          hasDefinedTerm: MOTIFS.map((motif) => ({
            '@type': 'DefinedTerm',
            '@id': url(`/tactics#${motif.slug}`),
            name: motif.name,
            description: motif.short,
            inDefinedTermSet: { '@id': url('/tactics#glossary') },
          })),
        },
        {
          '@type': 'FAQPage',
          '@id': url('/tactics#faq'),
          mainEntity: MOTIFS.slice(0, 8).map((motif) => ({
            '@type': 'Question',
            name: `What is a ${motif.name.toLowerCase()} in chess?`,
            acceptedAnswer: { '@type': 'Answer', text: `${motif.short} ${motif.body}` },
          })),
        },
      ],
    });
  }
}
