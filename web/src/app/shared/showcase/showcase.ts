import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  afterNextRender,
  computed,
  effect,
  inject,
  input,
  signal,
  viewChild,
} from '@angular/core';

import { prefersReducedMotion } from '../../core/capability';
import { Reveal } from '../../core/reveal';
import type { Copy } from '../../i18n/types';
import {
  CLIPS,
  type Clip,
  type Device,
  FRAME,
  PANEL,
  PANELS,
  VIEWS,
  filmSrc,
  loopSrc,
  panelSrc,
  panelSrcset,
  posterSrc,
  shotSrc,
  shotSrcset,
} from '../../i18n/media';

/**
 * The app, in the visitor's own language, moving.
 *
 * Three decisions are worth knowing about.
 *
 * **One player, three chapters.** The obvious layout puts the three clips side
 * by side, and it costs two and a half megabytes to show a page where only one
 * of them can be watched at a time. So there is a single frame and the clips
 * are chapters of it: one download, and the two that are not playing cost
 * nothing at all.
 *
 * **Silent by default, narrated on request.** The looping cut has no audio
 * track — not a muted one, none — which is what makes a browser willing to
 * start it unasked. Pressing for the narration swaps to the other cut, the one
 * with a person in the corner speaking this language, and that one plays with
 * sound because a person asked for it.
 *
 * **Nothing loads above the fold it is below.** The `src` is empty until the
 * section is near the viewport; before that the element is a poster in a
 * bezel, at the exact aspect of the device, so arriving footage moves nothing.
 */
@Component({
  selector: 'bp-showcase',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [Reveal],
  templateUrl: './showcase.html',
  styleUrl: './showcase.scss',
  host: { '[attr.dir]': 'null' },
})
export class Showcase {
  readonly copy = input.required<Copy>();
  /** The locale's URL segment, which is also its folder under media/. */
  readonly slug = input.required<string>();

  protected readonly clips = CLIPS;
  protected readonly device = signal<Device>('iphone');
  protected readonly clip = signal<Clip>('play');
  protected readonly narrated = signal(false);
  protected readonly playing = signal(false);

  /** False until the section is worth spending a visitor's bandwidth on. */
  private readonly near = signal(false);
  private readonly video = viewChild<ElementRef<HTMLVideoElement>>('player');
  private stop: (() => void) | null = null;

  /**
   * The player element.
   *
   * Prefers the view child and falls back to a query, because the two disagree
   * for one render during hydration and the effect that drives playback must
   * not be the thing that finds out.
   */
  private player(): HTMLVideoElement | null {
    return this.video()?.nativeElement ?? this.element.nativeElement.querySelector('video') ?? null;
  }

  protected readonly views = computed(() => VIEWS[this.device()]);

  /**
   * The strip is a fixed height and the images scale to it, so the browser can
   * be told the rendered width once rather than being left to assume 100vw and
   * fetch the larger file on every phone.
   */
  protected readonly sizes = '(max-width: 40rem) 62vw, 22rem';

  protected readonly panels = PANELS;
  protected readonly panelWidth = PANEL.width;
  protected readonly panelHeight = PANEL.height;
  protected readonly panelAspect = `${PANEL.width} / ${PANEL.height}`;
  protected readonly panelSizes = '(max-width: 40rem) 44vw, 17rem';

  protected panelSet(name: string, type: 'avif' | 'webp'): string {
    return panelSrcset(this.slug(), name, type);
  }

  protected panelFallback(name: string): string {
    return panelSrc(this.slug(), name);
  }
  protected readonly frame = computed(() => FRAME[this.device()]);

  protected readonly poster = computed(() => posterSrc(this.device(), this.slug(), this.clip()));

  protected readonly src = computed(() => {
    if (!this.near()) return null;
    const [device, slug, clip] = [this.device(), this.slug(), this.clip()];
    return this.narrated() ? filmSrc(device, slug, clip) : loopSrc(device, slug, clip);
  });

  /** What the narrator says in this clip — the caption, whether or not it is heard. */
  protected readonly line = computed(() => this.copy().spoken[this.clip()]);

  protected readonly names = computed(() => {
    const modes = this.copy().modes;
    return { play: modes.play, tactics: modes.tactics, watch: modes.watch } as Record<Clip, string>;
  });

  private readonly element = inject<ElementRef<HTMLElement>>(ElementRef);

  constructor() {
    afterNextRender(() => {
      // The component's own element, not the view child. During hydration the
      // view child is not resolved when this runs, and a setup that bails out
      // on a missing element never gets a second chance — which is exactly the
      // shape of bug where the poster is correct, the markup is correct, and
      // the film is never requested at all.
      const frame = this.element.nativeElement.querySelector('.bezel');
      if (!frame || typeof IntersectionObserver !== 'function') {
        this.near.set(true);
        return;
      }

      // Nothing is watched until the page has finished loading its own things.
      //
      // On a phone the film is two megabytes and the fonts are forty kilobytes,
      // and on a throttled connection whichever the browser starts first takes
      // the pipe. Arming this observer at first render put the film ahead of
      // the text: first paint moved out to three seconds and the largest
      // element to nearly four, for a video that is below the fold and that
      // nobody had scrolled to yet.
      if (document.readyState === 'complete') this.arm(frame);
      else window.addEventListener('load', () => this.arm(frame), { once: true });
    });

    inject(DestroyRef).onDestroy(() => this.stop?.());

    // The source changes when the language, device, chapter or cut changes, and
    // a <video> whose src changed does not reload on its own.
    effect(() => {
      const src = this.src();
      const host = this.player();
      if (!host) return;

      if (!src) {
        host.removeAttribute('src');
        return;
      }
      if (host.getAttribute('src') === src) return;

      const narrated = this.narrated();
      host.muted = !narrated;
      host.loop = !narrated;
      host.setAttribute('src', src);
      // preload="none" means load() alone fetches nothing; play() is what
      // actually asks for the bytes, which is the behaviour this wants — the
      // file is fetched at the moment it is going to be watched and not before.
      host.load();

      this.start(host);
    });
  }

  /**
   * Start watching for the section to come near.
   *
   * 200px rather than the 400 this began with: on a phone the whole film
   * section sits just under the fold, and 400px of margin meant "immediately".
   */
  private arm(frame: Element): void {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          this.near.set(true);
          return;
        }
        // Off screen entirely: stop. A narrated clip that keeps talking to
        // somebody four sections further down is the worst thing a page can do.
        const video = this.element.nativeElement.querySelector('video');
        if (video && !video.paused) video.pause();
      },
      { rootMargin: '200px 0px', threshold: 0 },
    );
    observer.observe(frame);
    this.stop = () => observer.disconnect();
  }

  protected choose(clip: Clip): void {
    if (this.clip() === clip) return;
    this.clip.set(clip);
    // A chapter change goes back to the silent loop: the visitor asked to see
    // a different part, not to be spoken to again.
    this.narrated.set(false);
  }

  protected switchDevice(device: Device): void {
    if (this.device() === device) return;
    this.device.set(device);
    this.narrated.set(false);
  }

  protected listen(): void {
    this.narrated.update((v) => !v);
    this.near.set(true);
  }

  /**
   * Ask it to play, if it should be playing.
   *
   * Called on the source change and again when the browser says it has enough
   * to start, because those are not the same moment: a `play()` issued against
   * a source that has not begun to arrive is rejected outright, and there is no
   * second attempt unless one is arranged. The symptom is a film that is fully
   * downloaded, correctly sized, and frozen on its poster.
   */
  private start(host: HTMLVideoElement): void {
    // Reduced motion means somebody has said things should not move unasked.
    // The narrated cut was asked for, so it plays either way.
    if (!this.narrated() && prefersReducedMotion()) return;
    void host.play().catch(() => this.playing.set(false));
  }

  protected onCanPlay(): void {
    const host = this.player();
    if (host?.paused) this.start(host);
  }

  protected onPlay(): void {
    this.playing.set(true);
  }

  protected onPause(): void {
    this.playing.set(false);
  }

  /** The narrated cut ends; the loop should come back rather than a frozen frame. */
  protected onEnded(): void {
    this.narrated.set(false);
  }

  protected srcset(view: string, type: 'avif' | 'webp'): string {
    return shotSrcset(this.device(), this.slug(), view, type);
  }

  protected fallback(view: string): string {
    return shotSrc(this.device(), this.slug(), view);
  }

  protected caption(view: string): readonly [string, string] {
    return this.copy().shots[view as keyof Copy['shots']];
  }
}
