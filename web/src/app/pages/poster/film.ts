import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  afterNextRender,
  viewChild,
} from '@angular/core';

import { FILM_FPS, FILM_SECONDS, TitleSequence } from '../../three/title-sequence';

/** The hero's stage colour, which is what the canvas hangs in front of. */
const STAGE = '#04050c';

/**
 * The opening film, shot frame by frame — a render target, not a page.
 *
 * The hero shows this while three.js is on its way, and then takes over from
 * it mid-shot. That only works if the film is the scene rather than a video of
 * something like it, which is why this drives the real `TitleSequence`: same
 * camera, same lights, same seeded grain and dust, same game played out at the
 * same pace. `TitleSequence.seek` winds a fresh copy of the scene forward to
 * whatever second the film reached, and the first frame it draws is the frame
 * the film was on.
 *
 * NOT ROUTED IN PRODUCTION, and driven by `tools/overture.py` rather than by
 * hand: it renders each frame and posts it to a receiver the tool is holding
 * open, which is the only way to get exact frame timing out of a browser.
 * Recording the canvas live gives frames spaced by however long the rendering
 * took, and a film whose seconds are not seconds cannot be seeked into.
 */
@Component({
  selector: 'bp-film',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <canvas #canvas [width]="width" [height]="height"></canvas>
    <canvas #plate [width]="width" [height]="height" hidden></canvas>
  `,
  styles: `
    :host {
      position: fixed;
      inset: 0;
      z-index: 99999;
      display: block;
      background: #04050c;
    }
  `,
})
export class Film {
  private readonly canvas = viewChild.required<ElementRef<HTMLCanvasElement>>('canvas');
  private readonly plate = viewChild.required<ElementRef<HTMLCanvasElement>>('plate');

  private readonly params = new URLSearchParams(
    typeof location === 'undefined' ? '' : location.search,
  );
  protected readonly width = Number(this.params.get('w') ?? 880);
  protected readonly height = Number(this.params.get('h') ?? 440);

  constructor() {
    afterNextRender(async () => {
      const canvas = this.canvas().nativeElement;
      const post = this.params.get('post');
      const seconds = Number(this.params.get('seconds') ?? FILM_SECONDS);

      const sequence = await TitleSequence.create(canvas, {
        width: this.width,
        height: this.height,
        // One device pixel per frame pixel: the file is a fixed size and the
        // browser shooting it may be running on any screen.
        pixelRatio: 1,
        quality: 'high',
        // The loop is never started — every frame here is asked for.
        still: false,
      });

      const report = (message: string) => {
        document.title = message;
      };

      // The scene is drawn on a transparent canvas, because in the hero it sits
      // over a poster that has to show through until it is ready. Read straight
      // off, that transparency is the film's ruin: the sky is nearly clear, and
      // taking a PNG of it divides colour by an alpha of almost nothing, which
      // turns a few dark stars into a red dome over the board. Compositing each
      // frame onto the stage's own colour first is both the fix and the truth —
      // a dark stage is exactly what the canvas hangs in front of.
      const plate = this.plate().nativeElement;
      const ctx = plate.getContext('2d');
      if (!ctx) return report('no 2d context');

      const frames = Math.round(seconds * FILM_FPS);
      for (let frame = 0; frame < frames; frame++) {
        sequence.seek(frame / FILM_FPS);
        sequence.renderStill();

        if (!post) continue;
        // Composited before anything is awaited: a WebGL drawing buffer is
        // cleared once the frame has been presented, so it has to be read in
        // the same task that drew it.
        ctx.fillStyle = STAGE;
        ctx.fillRect(0, 0, this.width, this.height);
        ctx.drawImage(canvas, 0, 0);
        const blob = await new Promise<Blob | null>((resolve) =>
          plate.toBlob(resolve, 'image/png'),
        );
        if (!blob) return report(`failed at frame ${frame}`);
        await fetch(`${post}/${String(frame).padStart(5, '0')}`, { method: 'POST', body: blob });
        report(`frame ${frame + 1} of ${frames}`);
      }

      if (post) await fetch(`${post}/done`, { method: 'POST' });
      report('done');
    });
  }
}
