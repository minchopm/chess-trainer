import { DestroyRef, Directive, ElementRef, afterNextRender, inject, input } from '@angular/core';

/**
 * Fades an element up the first time it enters the frame, and then forgets
 * about it.
 *
 * The important part is what happens when the fade does not run. Hiding
 * content and waiting for an observer is a bet, and if the bet is ever lost
 * the page is blank — so it is hedged twice: anything already in view when the
 * page loads is revealed immediately rather than waited for, and a timer
 * reveals everything else regardless after a few seconds. A missed animation
 * is a small loss; an invisible page is not.
 *
 * On the server this does nothing, so the prerendered HTML carries the
 * un-revealed state and the browser takes over from there.
 */
@Directive({
  selector: '[ctReveal]',
  host: { '[attr.data-reveal]': '""', '[style.--reveal-delay.ms]': 'ctReveal()' },
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
        reveal();
        return;
      }

      // Already on screen: reveal now. Waiting for an observer to tell us what
      // the browser already knows only produces a flash of nothing.
      const box = el.getBoundingClientRect();
      if (box.top < window.innerHeight && box.bottom > 0) {
        reveal();
        return;
      }

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
