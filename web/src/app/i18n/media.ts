/**
 * Where the films and the screenshots live.
 *
 * `media/` is deployed alongside the built site rather than through it: three
 * hundred megabytes copied into every `ng build` would make a build that has
 * nothing to do with them four times slower. deploy.sh syncs the folder to the
 * bucket separately and gives it a year-long cache, which it can because every
 * file in it is immutable — a new capture is a new run of tools/media.py.
 *
 * Paths are composed rather than looked up, so adding a language adds no code.
 */

export type Device = 'iphone' | 'ipad';

/** The three clips, in the order the app teaches them. */
export const CLIPS = ['play', 'tactics', 'watch'] as const;
export type Clip = (typeof CLIPS)[number];

/**
 * The screenshots, keyed the way their captions are.
 *
 * The order is the argument, not the order they were captured in: the board it
 * opens on, the coach pricing a bad move, the numbers on the squares, the
 * library, the two engines, the coach approving, and what costs nothing.
 */
export const VIEWS = {
  iphone: ['title', 'mistake', 'values', 'library', 'engines', 'coached', 'free'],
  ipad: ['title', 'mistake', 'values'],
} as const satisfies Record<Device, readonly string[]>;

export type View = (typeof VIEWS)['iphone'][number];

/** The widths each screenshot was written out at, narrow first. */
export const WIDTHS = { iphone: [420, 840], ipad: [640, 1280] } as const;

/** The aspect the bezel has to hold, so the box never has to be measured. */
export const FRAME = {
  iphone: { width: 1206, height: 2622 },
  ipad: { width: 2064, height: 2752 },
} as const;

const base = (device: Device, slug: string): string => `/media/video/${device}/${slug}`;

/** The narrated cut. Carries the spoken line, so it is the one with an audio track. */
export const filmSrc = (device: Device, slug: string, clip: Clip): string =>
  `${base(device, slug)}/${clip}.mp4`;

/**
 * The same footage without the narrator in the corner and with no audio track
 * at all — which is what lets it autoplay. A muted video is allowed to start
 * itself; a video with a silent track is still a video with a track, and some
 * browsers treat it as one.
 */
export const loopSrc = (device: Device, slug: string, clip: Clip): string =>
  `${base(device, slug)}/${clip}-silent.mp4`;

export const posterSrc = (device: Device, slug: string, clip: Clip): string =>
  `${base(device, slug)}/${clip}.jpg`;

const shot = (device: Device, slug: string, view: string): string =>
  `/media/shot/${device}/${slug}/${view}`;

export const shotSrcset = (device: Device, slug: string, view: string, type: 'avif' | 'webp') =>
  WIDTHS[device].map((w) => `${shot(device, slug, view)}-${w}.${type} ${w}w`).join(', ');

/** The largest one, for the `src` a browser falls back to. */
export const shotSrc = (device: Device, slug: string, view: string): string =>
  `${shot(device, slug, view)}-${WIDTHS[device].at(-1)}.webp`;
