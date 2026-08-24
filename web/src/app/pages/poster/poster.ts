import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  afterNextRender,
  viewChild,
} from '@angular/core';

import { TitleSequence } from '../../three/title-sequence';

/**
 * The hero's first frame, for export as a poster — a render target, not a page.
 *
 * The stage is blank for as long as it takes to fetch three.js and build the
 * scene, and a blank stage on the front page reads as a broken site rather than
 * as a loading one. The fix is a still that matches frame zero exactly, shown
 * underneath the canvas and revealed by the canvas being transparent until it
 * has something to show.
 *
 * Exactly is the operative word, which is why this renders from the real scene
 * rather than being painted by hand: same camera keyframe, same lights, same
 * pieces on the same squares.
 *
 * NOT ROUTED. To export, add a route temporarily:
 *
 *   { path: 'poster', loadComponent: () => import('./pages/poster/poster').then(m => m.Poster) }
 *
 * then screenshot at each aspect the hero uses — the camera widens below 0.9,
 * so one poster cannot serve both:
 *
 *   chrome --headless=new --window-size=1600,1000 --screenshot=wide.png .../poster
 *   chrome --headless=new --window-size=900,1600  --screenshot=tall.png .../poster
 */
@Component({
  selector: 'bp-poster',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<canvas #canvas></canvas>`,
  styles: `
    :host {
      position: fixed;
      inset: 0;
      z-index: 99999;
      display: block;
      background: #04050c;
    }
    canvas {
      display: block;
      width: 100%;
      height: 100%;
    }
  `,
})
export class Poster {
  private readonly canvas = viewChild.required<ElementRef<HTMLCanvasElement>>('canvas');

  constructor() {
    afterNextRender(async () => {
      // still: false, because `still` also skips building the bloom pass — and
      // a poster without the bloom the live scene has would announce itself the
      // moment the canvas faded in over it. The loop is simply never started.
      const canvas = this.canvas().nativeElement;
      const sequence = await TitleSequence.create(canvas, {
        width: canvas.clientWidth,
        height: canvas.clientHeight,
        pixelRatio: window.devicePixelRatio || 1,
        quality: 'high',
        still: false,
      });
      sequence.setProgress(0);
      sequence.renderStill();
    });
  }
}
