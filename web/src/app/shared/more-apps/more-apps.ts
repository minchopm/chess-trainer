import { afterNextRender, ChangeDetectionStrategy, Component, CUSTOM_ELEMENTS_SCHEMA, input } from '@angular/core';

const SRC = 'https://arte-soft.com/promo/more-apps.js';

/**
 * "More from Arte Soft": the other Arte Soft apps and the most-read guides of
 * their sites, in the reader's language. The block and its daily feed are
 * served from arte-soft.com (arte-soft-sites/promo), the same on every Arte
 * Soft site; it leaves out Brass Pawn itself by host name. This only places
 * the element and loads its script once, in the browser.
 *
 * It is the one thing on this site not served from brasspawn.com, so the
 * content policy (scripts/provision.sh) names arte-soft.com for the script
 * and the guide sites for their pictures.
 */
@Component({
  selector: 'bp-more-apps',
  changeDetection: ChangeDetectionStrategy.OnPush,
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
  host: { '[class.inline]': 'inline()' },
  template: `<arte-more-apps></arte-more-apps>`,
  styles: [
    `
      :host { display: block; }
      arte-more-apps {
        --ama-max: calc(var(--page) + 2 * var(--gutter));
        --ama-gutter: var(--gutter);
        --ama-margin: clamp(3rem, 8vw, 6rem) auto;
      }
      /* Inside a column that already has its gutter. */
      :host(.inline) arte-more-apps { --ama-max: none; --ama-gutter: 0; --ama-margin: 3rem 0; }
    `,
  ],
})
export class MoreApps {
  readonly inline = input(false);

  constructor() {
    afterNextRender(() => {
      if (document.querySelector(`script[src="${SRC}"]`)) return;
      const s = document.createElement('script');
      s.src = SRC;
      s.async = true;
      document.head.appendChild(s);
    });
  }
}
