import { ChangeDetectionStrategy, Component, input } from '@angular/core';

import { Reveal } from '../../core/reveal';

/**
 * The title card an inner page opens on. Same grammar as the hero — a slug
 * line, a title, a lede — at a quarter of the height and none of the WebGL.
 */
@Component({
  selector: 'bp-page-head',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [Reveal],
  template: `
    <div class="page">
      <p class="slug" ctReveal>{{ slug() }}</p>
      <h1 ctReveal="60">{{ title() }}</h1>
      @if (lede()) {
        <p class="lede measure" ctReveal="120">{{ lede() }}</p>
      }
      @if (meta()) {
        <p class="meta mono faint" ctReveal="160">{{ meta() }}</p>
      }
    </div>
  `,
  styles: `
    :host {
      display: block;
      padding: calc(4.25rem + clamp(3.5rem, 10vh, 7rem)) 0 clamp(2.5rem, 7vh, 4.5rem);
      border-bottom: 1px solid var(--rule-soft);
      background:
        radial-gradient(90% 120% at 78% -10%, rgba(214, 169, 95, 0.09), transparent 60%),
        linear-gradient(180deg, rgba(116, 168, 255, 0.05), transparent 45%);
    }

    h1 {
      font-size: clamp(2.5rem, 7vw, 5.25rem);
      margin: 0 0 1.5rem;
      max-width: 18ch;
    }

    .lede {
      margin: 0;
    }

    .meta {
      margin: 1.75rem 0 0;
      font-size: 0.6875rem;
      letter-spacing: 0.18em;
      text-transform: uppercase;
    }
  `,
})
export class PageHead {
  readonly slug = input.required<string>();
  readonly title = input.required<string>();
  readonly lede = input<string>('');
  readonly meta = input<string>('');
}
