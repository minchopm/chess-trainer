import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';

import { SiteFooter } from './shared/site-footer/site-footer';
import { SiteHeader } from './shared/site-header/site-header';

@Component({
  selector: 'bp-root',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterOutlet, SiteHeader, SiteFooter],
  template: `
    <bp-site-header />
    <main id="main"><router-outlet /></main>
    <bp-site-footer />
  `,
  styles: `
    :host {
      display: flex;
      min-height: 100svh;
      flex-direction: column;
    }

    main {
      flex: 1;
    }
  `,
})
export class App {}
