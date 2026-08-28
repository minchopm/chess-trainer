/**
 * What this device and this connection can reasonably be asked to carry.
 *
 * The title sequence is roughly six hundred kilobytes of three.js before it
 * draws anything. On a good connection that is a rounding error; on a metered
 * one it is rude, and on a phone with two gigabytes of memory it is a stutter.
 * Since the hero now has a poster that is a real frame of the scene, declining
 * to load it leaves a page that looks finished rather than one that looks
 * broken — which is what makes saying no here affordable.
 *
 * There is deliberately no WebGL probe. Probing costs a live WebGL context to
 * answer a question the scene itself answers a moment later by failing, and a
 * browser keeps only about sixteen contexts before it quietly starts refusing
 * new ones — so the probe's own cost is what eventually makes it say no.
 */

interface Connectivity {
  readonly saveData?: boolean;
  readonly effectiveType?: string;
}

/**
 * Whether it is worth downloading and running the scene at all.
 *
 * This used to refuse on `effectiveType` of `2g` as well as `slow-2g`, and
 * that was wrong in a way that took a while to see. `effectiveType` is not a
 * fact about the connection; it is a rolling estimate the browser makes from
 * recent round-trip times, and a page that opens with a burst of parallel
 * requests can push its own estimate down to `2g` on a fibre line. The scene
 * was then refused for the life of that page, and what a visitor got instead
 * was a ten-kilobyte still stretched across their screen.
 *
 * So only the signals that mean something now:
 *
 *   saveData      an explicit request from the person, not a guess
 *   slow-2g       the one tier that is genuinely hopeless for 600 kB
 *   deviceMemory  a hard property of the device, not a measurement
 *
 * And when the estimate is wrong, `watchCapability` below notices.
 */
export function shouldLoadScene(): boolean {
  if (typeof window === 'undefined') return false;

  const nav = navigator as Navigator & { deviceMemory?: number; connection?: Connectivity };

  if (nav.connection?.saveData) return false;
  if (nav.connection?.effectiveType === 'slow-2g') return false;
  if ((nav.deviceMemory ?? 4) <= 2) return false;

  return true;
}

/**
 * Call back once, if the connection later looks good enough to change the
 * answer above.
 *
 * The estimate that refused the scene is revised as the browser learns more,
 * and without this the page would keep showing a poster on a connection that
 * had turned out to be fine. Returns a function that stops listening.
 */
export function watchCapability(onImproved: () => void): () => void {
  const connection = (navigator as Navigator & { connection?: Connectivity & EventTarget })
    .connection;
  if (!connection?.addEventListener) return () => {};

  const check = () => {
    if (shouldLoadScene()) {
      stop();
      onImproved();
    }
  };
  const stop = () => connection.removeEventListener('change', check);
  connection.addEventListener('change', check);
  return stop;
}

/** Reduced motion still gets the scene — just one frame of it, per scroll. */
export function prefersReducedMotion(): boolean {
  return typeof matchMedia === 'function' && matchMedia('(prefers-reduced-motion: reduce)').matches;
}

/**
 * Quality tier. A tab that has never been visible reports a viewport of zero,
 * which would otherwise be read as "phone" and drop quality for the session.
 */
export function sceneQuality(): 'high' | 'low' {
  const viewport = window.innerWidth || screen.width || 1280;
  const weak = (navigator.hardwareConcurrency ?? 8) <= 4;
  return viewport <= 720 || weak ? 'low' : 'high';
}
