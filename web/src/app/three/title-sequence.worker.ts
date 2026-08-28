/// <reference lib="webworker" />

import { Game } from './games';
import { TitleSequence } from './title-sequence';

/**
 * Runs the title sequence on a worker thread against an OffscreenCanvas.
 *
 * That is the whole point: three.js is parsed here, the twenty-odd lathed
 * geometries are turned here, the two canvas textures are drawn here and every
 * frame is built and submitted here — so none of it competes with scrolling,
 * tapping or hydration on the main thread. The main thread's remaining job is
 * to post a scroll number when it changes and a size when the element moves.
 *
 * One thing is load-bearing and easy to get wrong: **a frame drawn to an
 * OffscreenCanvas outside a requestAnimationFrame callback is never presented
 * to the placeholder canvas.** A setTimeout loop renders at a happy sixty
 * frames a second and puts nothing at all on screen. Where worker rAF is
 * missing we therefore refuse the job rather than ship that: the main thread
 * hears `failed` and runs the identical scene itself.
 */

type Incoming =
  | {
      type: 'init';
      canvas: OffscreenCanvas;
      width: number;
      height: number;
      pixelRatio: number;
      quality: 'high' | 'low';
      still: boolean;
      progress: number;
      /** Where the opening film had got to, so the scene starts on its frame. */
      seekTo: number;
    }
  | { type: 'resize'; width: number; height: number; pixelRatio: number }
  | { type: 'progress'; value: number }
  | { type: 'running'; value: boolean }
  | { type: 'dispose' };

export type Outgoing =
  { type: 'ready' } | { type: 'painted' } | { type: 'failed' } | { type: 'game'; game: Game };

let sequence: TitleSequence | null = null;

addEventListener('message', async ({ data }: MessageEvent<Incoming>) => {
  switch (data.type) {
    case 'init': {
      if (typeof requestAnimationFrame !== 'function') {
        postMessage({ type: 'failed' } satisfies Outgoing);
        return;
      }
      try {
        sequence = await TitleSequence.create(data.canvas, {
          width: data.width,
          height: data.height,
          pixelRatio: data.pixelRatio,
          quality: data.quality,
          still: data.still,
          onGame: (game) => postMessage({ type: 'game', game } satisfies Outgoing),
          onPainted: () => postMessage({ type: 'painted' } satisfies Outgoing),
        });
        sequence.setProgress(data.progress);
        sequence.seek(data.seekTo);
        sequence.renderStill();
        // Start drawing immediately rather than waiting to be told. The hero is
        // at the top of the page, so it is on screen by definition at this
        // point, and making the first frame depend on an IntersectionObserver
        // callback arriving is a dependency with nothing to gain. The observer
        // still stops the loop when it scrolls away.
        if (!data.still) sequence.start();
        postMessage({ type: 'ready' } satisfies Outgoing);
      } catch {
        postMessage({ type: 'failed' } satisfies Outgoing);
      }
      break;
    }

    case 'resize':
      sequence?.resize(data.width, data.height, data.pixelRatio);
      if (sequence && !sequence.isRunning) sequence.renderStill();
      break;

    case 'progress':
      sequence?.setProgress(data.value);
      // With motion off there is no loop to pick the change up, so the frame
      // is drawn here instead.
      if (sequence && !sequence.isRunning) sequence.renderStill();
      break;

    case 'running':
      if (data.value) sequence?.start();
      else sequence?.stop();
      break;

    case 'dispose':
      sequence?.dispose();
      sequence = null;
      close();
      break;
  }
});
