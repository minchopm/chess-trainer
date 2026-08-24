import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';

import { Seo } from '../../core/seo';

@Component({
  selector: 'bp-not-found',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
    <div class="page">
      <p class="mono slugline">Scene missing</p>
      <p class="code">404</p>
      <h1>Not a legal move.</h1>
      <p class="lede measure">
        There is nothing at this address. The board is still where you left it.
      </p>
      <div class="actions">
        <a class="button button--solid" routerLink="/">Back to the opening</a>
        <a class="button" routerLink="/training">The training</a>
      </div>
    </div>
  `,
  styles: `
    :host {
      display: grid;
      place-items: center;
      min-height: 78svh;
      /* Clear of the fixed header, which would otherwise sit on the slug. */
      padding: 4.25rem var(--gutter) 0;
      text-align: center;
      background: radial-gradient(70% 60% at 50% 40%, rgba(214, 169, 95, 0.07), transparent 65%);
    }

    .slugline {
      color: var(--brass);
      letter-spacing: 0.4em;
      text-transform: uppercase;
      font-size: 0.625rem;
      margin: 0 0 2rem;
    }

    .code {
      font-family: var(--font-display);
      font-size: clamp(5rem, 20vw, 12rem);
      line-height: 0.8;
      margin: 0;
      color: transparent;
      background: linear-gradient(160deg, var(--brass-hot), var(--brass-deep) 80%);
      -webkit-background-clip: text;
      background-clip: text;
    }

    h1 {
      font-size: var(--title);
      margin: 1.5rem 0 1rem;
      font-style: italic;
    }

    .lede {
      margin: 0 auto 2.5rem;
    }

    .actions {
      display: flex;
      gap: 0.75rem;
      justify-content: center;
      flex-wrap: wrap;
    }
  `,
})
export class NotFound {
  constructor() {
    inject(Seo).apply({
      path: '/404',
      title: 'Not found',
      description: 'There is nothing at this address.',
    });
  }
}
