import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';

import { Seo } from '../../core/seo';
import { SITE } from '../../core/site';
import { PageHead } from '../../shared/page-head/page-head';

interface Component3rdParty {
  readonly name: string;
  readonly what: string;
  readonly licence: string;
  readonly holder: string;
  readonly href: string;
}

@Component({
  selector: 'bp-licences',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, PageHead],
  templateUrl: './licences.html',
  styleUrl: '../privacy/privacy.scss',
})
export class Licences {
  protected readonly site = SITE;

  protected readonly components: readonly Component3rdParty[] = [
    {
      name: 'Stockfish',
      what: 'The chess engine. Search, evaluation and the NNUE networks — the whole coach.',
      licence: 'GNU GPL v3',
      holder: 'The Stockfish developers, 2004–2026',
      href: 'https://github.com/official-stockfish/Stockfish',
    },
    {
      name: 'Reckless',
      what: 'The second chess engine. Its evaluation network is compiled into it, so there is no separate weights file.',
      licence: 'GNU AGPL v3',
      holder: 'The Reckless authors',
      href: 'https://github.com/codedeliveryservice/Reckless',
    },
    {
      name: 'Stockfish NNUE networks',
      what: 'The two neural network evaluation files the bundled engine expects.',
      licence: 'GNU GPL v3',
      holder: 'The Stockfish project',
      href: 'https://tests.stockfishchess.org/nns',
    },
    {
      name: 'Published game collections',
      what: '900 game scores for Watch, from published collections of the players’ own games. Scores only — no annotations are included.',
      licence: 'Not copyrightable (records of play)',
      holder: 'The moves are matters of record',
      href: 'https://www.pgnmentor.com/',
    },
    {
      name: 'Lichess puzzle database',
      what: '14,185 of the bundled tactics puzzles, with human-calibrated ratings and themes.',
      licence: 'CC0 1.0 (public domain)',
      holder: 'Lichess',
      href: 'https://database.lichess.org/',
    },
    {
      name: 'Lichess game archives',
      what: '1,624 rated games, for Guess the Elo. Usernames are not kept.',
      licence: 'CC0 1.0 (public domain)',
      holder: 'Lichess',
      href: 'https://database.lichess.org/',
    },
    {
      name: 'chess.js',
      what: 'Used by the project’s build tooling only. It is not in the iOS app.',
      licence: 'BSD 2-Clause',
      holder: 'Jeff Hlywa',
      href: 'https://github.com/jhlywa/chess.js',
    },
    {
      name: 'GameKit',
      what: 'Apple’s framework, used for online matchmaking and to carry moves.',
      licence: 'Apple SDK terms',
      holder: 'Apple Inc.',
      href: 'https://developer.apple.com/documentation/gamekit',
    },
    {
      name: 'Three.js',
      what: 'This website only — the title sequence on the front page.',
      licence: 'MIT',
      holder: 'three.js authors',
      href: 'https://github.com/mrdoob/three.js',
    },
    {
      name: 'Angular',
      what: 'This website only.',
      licence: 'MIT',
      holder: 'Google LLC and contributors',
      href: 'https://github.com/angular/angular',
    },
  ];

  constructor() {
    inject(Seo).apply({
      path: '/licences',
      title: 'Licences & attribution',
      updated: '2026-08-19',
      description:
        'Brass Pawn is AGPLv3 because it links two copyleft engines: Stockfish under the GPLv3 and Reckless under the AGPLv3. Every third-party component, its licence and its copyright holder, and where to get the complete corresponding source.',
    });
  }
}
