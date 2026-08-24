import { DestroyRef, Directive, ElementRef, afterNextRender, inject, input } from '@angular/core';

/**
 * Fades an element up the first time it enters the frame, and then forgets
 * about it.
 *
 * **Nothing is hidden until this runs.** The prerendered HTML carries no
 * hidden state at all; the browser paints the page, and only then does this
 * hide the elements that are off screen so they have somewhere to fade up
 * from. Nobody sees that happen, because by definition they are not looking at
 * them.
 *
 * It was the other way round — hidden in CSS, revealed by this — and it cost
 * three seconds of largest-contentful-paint on a phone. The text was in the
 * document from the first byte and stayed invisible until a hundred kilobytes
 * of JavaScript had downloaded, parsed and hydrated, which is a long time to
 * show somebody an empty screen in order to animate it.
 *
 * The fade is still hedged: anything on screen is never hidden in the first
 * place, and a timer reveals whatever the observer has not after a few
 * seconds. A missed animation is a small loss; an invisible page is not.
 */
@Directive({
  selector: '[ctReveal]',
  host: { '[style.--reveal-delay.ms]': 'ctReveal()' },
})
export class Reveal {
  /** Stagger, in milliseconds. */
  readonly ctReveal = input(0, {
    transform: (v: number | string | undefined) => (v === '' || v == null ? 0 : Number(v)),
  });

  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);

  constructor() {
    const destroyRef = inject(DestroyRef);

    afterNextRender(() => {
      const el = this.host.nativeElement;
      let observer: IntersectionObserver | null = null;
      let timer: ReturnType<typeof setTimeout> | undefined;

      const reveal = () => {
        el.setAttribute('data-reveal', 'in');
        observer?.disconnect();
        clearTimeout(timer);
      };

      if (
        matchMedia('(prefers-reduced-motion: reduce)').matches ||
        typeof IntersectionObserver === 'undefined'
      ) {
        return; // never hidden, so there is nothing to reveal
      }

      // Already on screen: leave it alone. Hiding something a person is looking
      // at in order to fade it back in is a flicker, not an animation.
      const box = el.getBoundingClientRect();
      if (box.top < window.innerHeight && box.bottom > 0) return;

      // Off screen: now it can be hidden, and now it has somewhere to come from.
      el.setAttribute('data-reveal', 'out');

      observer = new IntersectionObserver(
        (entries) => {
          if (entries.some((entry) => entry.isIntersecting)) reveal();
        },
        { rootMargin: '0px 0px -12% 0px', threshold: 0.08 },
      );
      observer.observe(el);

      timer = setTimeout(reveal, 4000);
      destroyRef.onDestroy(reveal);
    });
  }
}
