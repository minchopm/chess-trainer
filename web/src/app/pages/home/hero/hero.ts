import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  OnDestroy,
  afterNextRender,
  computed,
  inject,
  signal,
  viewChild,
} from '@angular/core';
import { RouterLink } from '@angular/router';

import {
  prefersReducedMotion,
  sceneQuality,
  shouldLoadScene,
  watchCapability,
} from '../../../core/capability';
import { SITE } from '../../../core/site';
import type { Game } from '../../../three/games';
import type { TitleSequence } from '../../../three/title-sequence';

/** A title card: when it comes up, and when it goes. */
interface Card {
  readonly at: number;
  readonly until: number;
}

const CARDS: readonly Card[] = [
  { at: 0.0, until: 0.2 },
  { at: 0.26, until: 0.47 },
  { at: 0.53, until: 0.73 },
  { at: 0.79, until: 1.01 },
];

/**
 * Whether to try the OffscreenCanvas worker before the main thread.
 *
 * Off, and the reason is worth writing down rather than rediscovering.
 *
 * The worker path is complete and correct as far as it can be observed from
 * here: the module loads, the scene builds, geometry and textures are made off
 * the main thread, and messages flow both ways — `game` and `ready` arrive.
 * What never arrived, in either environment available for testing, is a single
 * painted frame: worker `requestAnimationFrame` never ticked, and a frame
 * rendered into an OffscreenCanvas outside a rAF callback is never presented.
 *
 * That failure is invisible with the poster underneath, which is precisely why
 * it must not be the default. `transferControlToOffscreen()` is one-way, so a
 * worker that cannot paint takes the canvas with it — there is no falling back
 * to the main thread afterwards, and those users would get a still image where
 * they used to get the film.
 *
 * Turn this on to try it on real hardware. If the hero animates, it is a
 * straight win: three.js is 612 kB that stops being parsed, built and drawn on
 * the thread that also has to answer taps.
 */
const USE_WORKER = false;

/** How long the canvas takes to cover the film, in milliseconds. Matches the SCSS. */
const FADE = 340;

/**
 * Whatever is drawing the scene, seen from here.
 *
 * The worker and the main thread are told the same four things in the same
 * order, so the component has no idea which one it is talking to and there is
 * only one copy of the logic that decides when to say them.
 */
interface Driver {
  resize(width: number, height: number, pixelRatio: number): void;
  setProgress(value: number): void;
  setRunning(value: boolean): void;
  dispose(): void;
}

/**
 * The opening. A tall track with a sticky stage in it: the page scrolls, the
 * camera moves, and four cards come up and go.
 *
 * There are three ways this ends up on screen, in order of preference:
 *
 *   1. **A worker**, rendering into an OffscreenCanvas. Everything three.js
 *      does happens off the main thread, so a page that is still hydrating —
 *      or a finger that is still scrolling — is not competing with it.
 *   2. **The main thread**, running the identical scene, where the browser has
 *      no OffscreenCanvas or no worker rAF.
 *   3. **Neither.** No WebGL, data-saver on, a slow connection or a small
 *      device, and the poster stays — which is a real frame of the scene, so
 *      the page looks finished rather than unfinished.
 */
@Component({
  selector: 'bp-hero',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  templateUrl: './hero.html',
  styleUrl: './hero.scss',
})
export class Hero implements OnDestroy {
  protected readonly site = SITE;

  private readonly track = viewChild.required<ElementRef<HTMLElement>>('track');
  private readonly canvas = viewChild.required<ElementRef<HTMLCanvasElement>>('canvas');
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);

  protected readonly progress = signal(0);
  protected readonly rendering = signal(false);
  protected readonly lit = signal(false);
  /** The game currently being played out behind the title, if one is. */
  protected readonly playing = signal<Game | null>(null);

  /** Opacity per card, so the template stays free of arithmetic. */
  protected readonly cards = computed(() => {
    const p = this.progress();
    return CARDS.map((card) => {
      const fade = 0.06;
      // `at` is where the card is fully up, not where it starts arriving — so
      // the first card is already on screen when the page loads at p = 0.
      const rise = Math.min(1, Math.max(0, (p - (card.at - fade)) / fade));
      const fall = Math.min(1, Math.max(0, (card.until - p) / fade));
      return { opacity: Math.min(rise, fall), lift: (1 - rise) * 22 - (1 - fall) * 10 };
    });
  });

  private driver: Driver | null = null;
  private film: HTMLVideoElement | null = null;
  private ticking = false;
  private inView = false;
  private destroyed = false;
  private teardown: (() => void)[] = [];

  constructor() {
    afterNextRender(() => void this.mount());
  }

  private async mount(): Promise<void> {
    const onScroll = () => {
      if (this.ticking) return;
      this.ticking = true;
      requestAnimationFrame(() => {
        this.ticking = false;
        this.measure();
      });
    };

    window.addEventListener('scroll', onScroll, { passive: true });
    window.addEventListener('resize', onScroll, { passive: true });
    this.teardown.push(() => {
      window.removeEventListener('scroll', onScroll);
      window.removeEventListener('resize', onScroll);
    });
    this.measure();

    // The curtain goes up either way; whether there is a film behind it is the
    // next question.
    requestAnimationFrame(() => this.lit.set(true));

    if (!shouldLoadScene()) {
      // Refused for now, not for ever. `effectiveType` is an estimate the
      // browser revises, and a page that opened during a slow moment should
      // not be stuck with a still of the scene for the rest of its life.
      this.teardown.push(watchCapability(() => void this.startScene()));
      return;
    }

    await this.startScene();
  }

  /**
   * Build the scene and wire it to the page.
   *
   * Separate from `mount` so that a connection which was misjudged at load can
   * call it later — mount also installs the scroll listeners, and calling that
   * twice would install them twice.
   */
  private async startScene(): Promise<void> {
    if (this.driver || this.destroyed) return;

    const canvas = this.canvas().nativeElement;
    const stage = canvas.parentElement;
    if (!stage) return;

    const quality = sceneQuality();
    const still = prefersReducedMotion();

    // The film goes up first, because it is the thing that covers the wait it
    // is about to be handed over from.
    if (!still) this.startFilm(stage, canvas);

    const size = () => ({
      width: stage.clientWidth,
      height: stage.clientHeight,
      pixelRatio: window.devicePixelRatio || 1,
    });

    const driver =
      this.startWorker(canvas, size(), quality, still) ??
      (await this.startMainThread(canvas, size(), quality, still));

    if (!driver || this.destroyed) {
      driver?.dispose();
      return;
    }
    this.driver = driver;
    driver.setProgress(this.progress());

    // The element drives the size, not the window: a tab restored from the
    // background, a split view and a rotated phone all change the element
    // without necessarily firing a window resize.
    const resizeObserver = new ResizeObserver(() => {
      const { width, height, pixelRatio } = size();
      driver.resize(width, height, pixelRatio);
    });
    resizeObserver.observe(stage);
    this.teardown.push(() => resizeObserver.disconnect());

    if (still) return;

    // Nothing renders while the hero is off screen: a title sequence nobody is
    // watching should not cost a phone its battery. A hidden tab needs no such
    // rule — the browser stops serving animation frames on its own.
    const intersection = new IntersectionObserver(
      ([entry]) => {
        this.inView = entry.isIntersecting;
        driver.setRunning(entry.isIntersecting);
      },
      { threshold: 0 },
    );
    intersection.observe(this.host.nativeElement);
    this.teardown.push(() => intersection.disconnect());

    const onVisibility = () => {
      if (document.hidden) return;
      const { width, height, pixelRatio } = size();
      driver.resize(width, height, pixelRatio);
      this.measure();
      driver.setRunning(this.inView);
    };
    document.addEventListener('visibilitychange', onVisibility);
    this.teardown.push(() => document.removeEventListener('visibilitychange', onVisibility));
  }

  // ── the two ways of driving it ──────────────────────────────────────────

  /** Preferred: hand the canvas to a worker and never touch it again. */
  private startWorker(
    canvas: HTMLCanvasElement,
    size: { width: number; height: number; pixelRatio: number },
    quality: 'high' | 'low',
    still: boolean,
  ): Driver | null {
    if (!USE_WORKER) return null;
    if (typeof Worker === 'undefined') return null;
    if (typeof canvas.transferControlToOffscreen !== 'function') return null;

    let worker: Worker;
    try {
      worker = new Worker(new URL('../../../three/title-sequence.worker', import.meta.url), {
        type: 'module',
      });
    } catch {
      return null; // module workers unsupported — the canvas is untouched
    }

    let offscreen: OffscreenCanvas;
    try {
      offscreen = canvas.transferControlToOffscreen();
    } catch {
      worker.terminate();
      return null;
    }

    // A watchdog, because 'ready' only means the scene was built. If the loop
    // never reports a painted frame — the failure mode where a worker renders
    // happily into a canvas nothing ever presents — the worker is shut down
    // and the poster, which is a real frame of this scene, simply stays.
    const watchdog = setTimeout(() => {
      if (!this.rendering()) worker.terminate();
    }, 4000);
    this.teardown.push(() => clearTimeout(watchdog));

    worker.addEventListener('message', ({ data }) => {
      if (data?.type === 'painted') {
        clearTimeout(watchdog);
        this.reveal();
      }
      // The scene refused the job — most likely no rAF in this worker, which
      // would render frames that are never presented. Nothing to do but leave
      // the poster; transferControlToOffscreen is one-way, so the main-thread
      // path is no longer available for this canvas.
      if (data?.type === 'failed') {
        clearTimeout(watchdog);
        worker.terminate();
      }
      if (data?.type === 'game') this.playing.set(data.game as Game);
    });

    worker.postMessage(
      {
        type: 'init',
        canvas: offscreen,
        ...size,
        quality,
        still,
        progress: this.progress(),
        // Read before the worker has even loaded its module, so this runs a
        // little behind the film — a tenth of a second at the outside, against
        // a swing that takes sixteen seconds to go out and back.
        seekTo: this.filmTime(),
      },
      [offscreen],
    );

    return {
      resize: (width, height, pixelRatio) =>
        worker.postMessage({ type: 'resize', width, height, pixelRatio }),
      setProgress: (value) => worker.postMessage({ type: 'progress', value }),
      setRunning: (value) => worker.postMessage({ type: 'running', value }),
      dispose: () => {
        worker.postMessage({ type: 'dispose' });
        worker.terminate();
      },
    };
  }

  /** Fallback: the identical scene, on this thread. */
  private async startMainThread(
    canvas: HTMLCanvasElement,
    size: { width: number; height: number; pixelRatio: number },
    quality: 'high' | 'low',
    still: boolean,
  ): Promise<Driver | null> {
    try {
      const { TitleSequence } = await import('../../../three/title-sequence');
      if (this.destroyed) return null;

      const sequence: TitleSequence = await TitleSequence.create(canvas, {
        ...size,
        quality,
        still,
        onGame: still ? undefined : (game) => this.playing.set(game),
        onPainted: () => this.reveal(),
      });
      // Read here, at the last possible moment: building the scene is most of
      // the wait the film is covering, so the film is further along now than it
      // was when the wait began.
      sequence.seek(this.filmTime());
      sequence.renderStill();
      if (still) {
        // No loop will run, so the still above is all there will ever be.
        this.reveal();
      } else {
        // Start drawing now rather than waiting to be told. The hero is at the
        // top of the page, so it is on screen by definition at this point, and
        // making the first frame wait for an IntersectionObserver callback is
        // a dependency with nothing to gain. The observer still stops the loop
        // when it scrolls out of view.
        sequence.start();
      }

      return {
        resize: (width, height, pixelRatio) => {
          sequence.resize(width, height, pixelRatio);
          if (!sequence.isRunning) sequence.renderStill();
        },
        setProgress: (value) => {
          sequence.setProgress(value);
          if (!sequence.isRunning) sequence.renderStill();
        },
        setRunning: (value) => (value ? sequence.start() : sequence.stop()),
        dispose: () => sequence.dispose(),
      };
    } catch {
      return null;
    }
  }

  // ── the opening film ────────────────────────────────────────────────────

  /**
   * Puts up the film the scene is going to take over from.
   *
   * The poster underneath is a real frame of this scene, which was enough
   * while it was on screen for half a second. It is not enough at the top of a
   * page somebody has just arrived at: a chess board that does not move is a
   * photograph of a chess board, and no amount of it being the right photograph
   * changes that.
   *
   * So the film — six seconds of this same scene, shot from it frame by frame
   * by `tools/overture.py`. It plays while three.js is fetched, parsed and
   * built, and then the live scene is wound forward to whatever second the film
   * reached and drawn over it. Everything either of them does is a function of
   * elapsed time from zero, and every source of noise in the scene is seeded,
   * so the frame the film is holding and the frame the scene starts on are the
   * same picture.
   *
   * Built here rather than in the template because it should not exist in
   * thirty-one prerendered pages: it is only ever wanted by a browser that is
   * about to load a scene, and a `<video>` in the HTML is one the crawler and
   * the reduced-motion reader both have to be talked out of.
   */
  private startFilm(stage: HTMLElement, before: HTMLElement): void {
    // The camera widens below 0.9 aspect, so a wide film on a phone is not the
    // shot the scene will take over with — it is a different one, cropped.
    const wide = window.matchMedia('(min-aspect-ratio: 9/10)').matches;
    const shape = wide ? 'wide' : 'tall';

    const video = document.createElement('video');
    video.className = 'overture';
    video.muted = true;
    video.defaultMuted = true;
    video.playsInline = true;
    video.loop = false;
    video.preload = 'auto';
    video.setAttribute('aria-hidden', 'true');
    // AV1 first: on a shot this dark it is worth about a third of the bytes,
    // and everything that cannot decode it falls through to the H.264.
    for (const [type, extension] of [
      ['video/webm', 'webm'],
      ['video/mp4', 'mp4'],
    ] as const) {
      const source = document.createElement('source');
      source.src = `/overture/overture-${shape}.${extension}`;
      source.type = type;
      video.append(source);
    }

    // Both the attribute and the call, which are not the same request. The
    // attribute is what a browser consults when it decides whether a tab that
    // is not being looked at yet may start playing; the call is what starts it
    // in a tab that is. A page opened in a background tab — restored on
    // startup, opened in a new tab from somewhere else — gets only the first.
    video.autoplay = true;
    stage.insertBefore(video, before);
    this.film = video;

    // Refusal is a real outcome and not an error: a data-saver setting, a
    // browser that wants a gesture first. Nothing to report, because what is
    // underneath is the poster, which is where this began. But a refusal while
    // the tab is hidden is worth one more try when it is looked at.
    const attempt = () => {
      // Only while this is still the film. After the handover it is a detached
      // element with no source, and asking it to play is asking for nothing.
      if (this.film === video) void video.play().catch(() => undefined);
    };
    attempt();
    video.addEventListener('canplay', attempt, { once: true });
    document.addEventListener('visibilitychange', attempt);
    this.teardown.push(() => document.removeEventListener('visibilitychange', attempt));
  }

  /**
   * How far into the film we are, in seconds.
   *
   * Zero if there is no film, if it never started, or if it was never allowed
   * to play — and zero is the honest answer in all three cases, because zero is
   * where the scene would otherwise begin.
   */
  private filmTime(): number {
    const film = this.film;
    if (!film || film.readyState < 2) return 0;
    return Math.max(0, Math.min(film.currentTime, film.duration || 0));
  }

  /**
   * The handover: the canvas comes up, and the film goes when it is covered.
   *
   * The two are the same picture, so this could be a cut — except that the film
   * has been through an encoder at a bitrate chosen for a placeholder, and
   * cutting from that to a clean render is a visible sharpening. A third of a
   * second of dissolve hides it, and both keep running at the same rate
   * underneath, so nothing drifts apart while it happens.
   */
  private reveal(): void {
    if (this.rendering()) return;
    this.rendering.set(true);

    const film = this.film;
    if (!film) return;
    this.film = null;
    window.setTimeout(() => {
      film.pause();
      film.removeAttribute('src');
      film.load(); // lets go of the decoder rather than leaving it parked
      film.remove();
    }, FADE);
  }

  // ── scroll ──────────────────────────────────────────────────────────────

  private measure(): void {
    const el = this.track().nativeElement;
    const travel = el.offsetHeight - window.innerHeight;
    const scrolled = window.scrollY - el.offsetTop;
    const p = travel > 0 ? Math.min(1, Math.max(0, scrolled / travel)) : 0;
    this.progress.set(p);
    this.driver?.setProgress(p);
  }

  ngOnDestroy(): void {
    this.destroyed = true;
    for (const off of this.teardown) off();
    this.driver?.dispose();
    this.film?.pause();
    this.film?.remove();
  }
}
