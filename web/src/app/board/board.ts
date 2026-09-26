import {
  afterNextRender,
  ChangeDetectionStrategy,
  Component,
  computed,
  DestroyRef,
  effect,
  ElementRef,
  inject,
  Injectable,
  input,
  signal,
  viewChild,
} from '@angular/core';

import { BoardConfig, DEFAULT_CONFIG, Dimension, placeholder, savedConfig, saveConfig } from './config';
import { draw } from './draw2d';
import type { Board3D } from './scene3d';

/**
 * The reader's board, shared by every board on the page — the site's
 * Settings → Appearance. Read from their browser once it is running, so the
 * prerendered page and the first frame are the default walnut and nobody's
 * choice is ever sent anywhere.
 */
@Injectable({ providedIn: 'root' })
export class BoardSettings {
  readonly config = signal<BoardConfig>(DEFAULT_CONFIG);
  private loaded = false;

  load(): void {
    if (this.loaded) return;
    this.loaded = true;
    this.config.set(savedConfig());
  }

  update(change: Partial<BoardConfig>): void {
    const next = { ...this.config(), ...change };
    this.config.set(next);
    saveConfig(next);
  }
}

/**
 * A position, drawn the way the app draws it — flat, or in the round.
 *
 * What the page carries is the position and nothing else: the prerendered
 * HTML is an empty square in the board's two colours, and the browser draws
 * the rest from the reader's settings when the board scrolls into view. Sixty
 * boards on a page were sixty SVGs of sixty-four squares each, which was most
 * of the page's weight; now they are sixty lines of FEN.
 */
@Component({
  selector: 'bp-board',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="frame" role="img" [attr.aria-label]="label()" [style.background]="background()">
      <canvas #flat class="layer" [class.hidden]="round()"></canvas>
      @if (round()) {
        <canvas #solid class="layer solid"></canvas>
      }
    </div>
  `,
  styles: `
    :host { display: block; }
    .frame { position: relative; aspect-ratio: 1; border-radius: 3px; overflow: hidden; }
    .layer { position: absolute; inset: 0; width: 100%; height: 100%; display: block; }
    .solid { cursor: grab; background: radial-gradient(120% 90% at 50% 20%, #1a1c24, #05060a); }
    .solid:active { cursor: grabbing; }
    .hidden { visibility: hidden; }
  `,
})
export class Board {
  readonly fen = input.required<string>();
  readonly last = input<{ from: string; to: string } | null>(null);
  /** Black at the bottom — for a story told from Black's side. */
  readonly flip = input(false);
  readonly label = input('Chess position');
  /** Hold the board flat whatever the reader chose: a list of thumbnails is not sixty WebGL scenes. */
  readonly flat = input(false);
  /** Leave the rim off, which a thumbnail has no room for. */
  readonly bare = input(false);

  private readonly settings = inject(BoardSettings);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  private readonly destroy = inject(DestroyRef);
  private readonly flatCanvas = viewChild<ElementRef<HTMLCanvasElement>>('flat');
  private readonly solidCanvas = viewChild<ElementRef<HTMLCanvasElement>>('solid');

  private readonly visible = signal(false);
  private readonly width = signal(0);
  private scene: Board3D | null = null;
  private sceneFor: HTMLCanvasElement | null = null;
  /** The latest draw asked for; an earlier one still loading is dropped. */
  private drawn = 0;

  protected readonly config = computed<BoardConfig>(() => {
    const config = this.settings.config();
    return {
      ...config,
      dimension: (this.flat() ? '2d' : config.dimension) as Dimension,
      coordinates: this.bare() ? false : config.coordinates,
    };
  });
  protected readonly round = computed(() => this.config().dimension === '3d');
  protected readonly background = computed(() => placeholder(this.config()));

  constructor() {
    afterNextRender(() => {
      this.settings.load();
      const element = this.host.nativeElement;
      // Drawn once near the screen, and not before: a list of sixty boards
      // should cost what the reader scrolls past, not what the page holds.
      const seen = new IntersectionObserver(
        (entries) => {
          if (entries.some((e) => e.isIntersecting)) {
            this.visible.set(true);
            seen.disconnect();
          }
        },
        { rootMargin: '300px' },
      );
      seen.observe(element);
      const sized = new ResizeObserver(() => this.width.set(element.clientWidth));
      sized.observe(element);
      this.width.set(element.clientWidth);
      this.destroy.onDestroy(() => {
        seen.disconnect();
        sized.disconnect();
        this.scene?.dispose();
      });
    });

    effect(() => {
      if (!this.visible() || !this.width()) return;
      const config = this.config();
      const position = { fen: this.fen(), last: this.last(), flip: this.flip() };
      const side = this.width();
      const ticket = ++this.drawn;
      const current = () => ticket === this.drawn;
      if (config.dimension === '3d') {
        void this.drawRound(position, config, side, current);
      } else {
        const canvas = this.flatCanvas()?.nativeElement;
        if (canvas) void draw(canvas, side, position, config, current);
      }
    });
  }

  /** three.js arrives with the first round board, and only then. */
  private async drawRound(
    position: { fen: string; last: { from: string; to: string } | null; flip: boolean },
    config: BoardConfig,
    side: number,
    current: () => boolean,
  ): Promise<void> {
    const canvas = this.solidCanvas()?.nativeElement;
    if (!canvas) return;
    if (this.sceneFor !== canvas) {
      // The canvas is new — 3D was switched off and on — and a scene belongs
      // to the canvas it was made for.
      this.scene?.dispose();
      this.scene = null;
      this.sceneFor = canvas;
    }
    if (!this.scene) {
      const { Board3D } = await import('./scene3d');
      // Two draws can wait on the import together; the first one back builds it.
      if (this.sceneFor !== canvas) return;
      this.scene ??= new Board3D(canvas);
    }
    if (!current()) return;
    this.scene.resize(side, side);
    this.scene.show(position, config);
  }
}
