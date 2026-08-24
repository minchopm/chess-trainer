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

/** Whether it is worth downloading and running the scene at all. */
export function shouldLoadScene(): boolean {
  if (typeof window === 'undefined') return false;

  const nav = navigator as Navigator & { deviceMemory?: number; connection?: Connectivity };

  // Data-saver is an explicit request, not a hint.
  if (nav.connection?.saveData) return false;
  if (/(^|-)(2g|slow-2g)$/.test(nav.connection?.effectiveType ?? '')) return false;
  if ((nav.deviceMemory ?? 4) <= 2) return false;

  return true;
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
