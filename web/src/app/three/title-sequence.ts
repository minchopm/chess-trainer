import {
  ACESFilmicToneMapping,
  AdditiveBlending,
  AmbientLight,
  BoxGeometry,
  CanvasTexture,
  EquirectangularReflectionMapping,
  BufferAttribute,
  BufferGeometry,
  CatmullRomCurve3,
  Color,
  DirectionalLight,
  Fog,
  Group,
  Mesh,
  MeshPhysicalMaterial,
  MeshStandardMaterial,
  PCFShadowMap,
  PMREMGenerator,
  PerspectiveCamera,
  PlaneGeometry,
  PointLight,
  Points,
  PointsMaterial,
  SRGBColorSpace,
  Scene,
  SpotLight,
  Vector2,
  Vector3,
  WebGLRenderer,
} from 'three';
import { EffectComposer } from 'three/examples/jsm/postprocessing/EffectComposer.js';
import { OutputPass } from 'three/examples/jsm/postprocessing/OutputPass.js';
import { RenderPass } from 'three/examples/jsm/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/examples/jsm/postprocessing/UnrealBloomPass.js';

import { Canvas2D, boardTexture, dustTexture, scratch } from './board';
import { PlayingBoard } from './board-play';
import { GAMES, Game } from './games';
import { PIECE_KINDS, PieceKind, buildPieceGeometry } from './pieces';

/**
 * The camera's four shots, cut as one continuous move.
 *
 * Read as a pair of splines — where the lens is, and what it is pointed at —
 * both sampled by the same scroll value. Cutting would be cheaper and would
 * also throw away the only thing a scroll-driven camera is good at.
 */
const EYE = new CatmullRomCurve3(
  [
    new Vector3(8.2, 4.4, -9.4), // 1. three-quarters on, the whole board in shot
    new Vector3(5.2, 5.0, -10.2),
    new Vector3(1.2, 6.6, -9.4), // 2. crane, looking back down the board
    new Vector3(-6.2, 4.4, -5.0),
    new Vector3(-9.6, 2.4, 1.6), // 3. a low sweep across from the queen's side
    new Vector3(-5.4, 5.6, 10.2),
    new Vector3(0.0, 10.6, 16.2), // 4. and away, the board small in the dark
  ],
  false,
  'catmullrom',
  0.3,
);

// Aimed a little above the board rather than at it, which drops the board into
// the lower half of the frame and leaves the top clear for the title.
const TARGET = new CatmullRomCurve3(
  [
    new Vector3(1.8, 2.5, -2.4),
    new Vector3(1.6, 2.2, -2.2),
    new Vector3(1.4, 1.7, -1.8),
    new Vector3(0.7, 1.0, -0.8),
    new Vector3(0.0, 0.6, 0.0),
    new Vector3(0.0, 0.3, 0.0),
    new Vector3(0.0, 0.0, 0.0),
  ],
  false,
  'catmullrom',
  0.3,
);

/**
 * How the games are paced.
 *
 * Slow enough to follow a move, fast enough that a whole game fits inside the
 * attention a title sequence gets. At these numbers the Opera Game runs about
 * forty seconds and the Immortal about a minute.
 */
const BETWEEN_MOVES = 0.72;
const FIRST_MOVE_DELAY = 2.4;
const AFTER_MATE = 4.6;

/**
 * Hands control back to the browser.
 *
 * `scheduler.yield()` where it exists, because it resumes at the front of the
 * queue rather than behind whatever else arrived — a `setTimeout` fallback
 * finishes the build eventually, but can be starved by a busy page.
 */
function pause(): Promise<void> {
  const scheduler = (globalThis as { scheduler?: { yield?: () => Promise<void> } }).scheduler;
  return scheduler?.yield ? scheduler.yield() : new Promise((r) => setTimeout(r, 0));
}

export interface TitleSequenceOptions {
  /**
   * The size to render at, in CSS pixels, and the ratio to multiply by.
   *
   * Passed in rather than measured, because on the worker path there is no
   * element to measure and no `window` to ask. The main thread owns the
   * ResizeObserver either way and posts the numbers here.
   */
  readonly width: number;
  readonly height: number;
  readonly pixelRatio: number;
  /** Low quality drops post-processing and shadow resolution, not content. */
  readonly quality?: 'high' | 'low';
  /** When true the scene renders exactly one frame and then stops. */
  readonly still?: boolean;
  /** Called whenever a new game starts, so the page can caption it. */
  readonly onGame?: (game: Game) => void;
  /**
   * Called from inside the animation loop once a few frames have gone out.
   *
   * `ready` only says the scene was built; this says it is being drawn. On the
   * worker path those are genuinely different claims, because a frame rendered
   * into an OffscreenCanvas is only presented from within a requestAnimationFrame
   * callback — so a scene can be complete, correct, and invisible.
   */
  readonly onPainted?: () => void;
}

/**
 * The WebGL title sequence behind the first screen.
 *
 * Deliberately framework-free: it owns a canvas, a render loop and its own
 * teardown, and knows nothing about Angular. The component that mounts it does
 * nothing but hand it a canvas and a scroll number.
 */
export class TitleSequence {
  private readonly renderer: WebGLRenderer;
  private readonly scene = new Scene();
  private readonly camera: PerspectiveCamera;
  private composer: EffectComposer | null = null;
  private bloom: UnrealBloomPass | null = null;
  private readonly board = new Group();
  private play!: PlayingBoard;
  private practical!: PointLight;
  private dust!: Points;
  private keyLight!: SpotLight;
  private readonly disposables: { dispose(): void }[] = [];

  private frame = 0;
  private running = false;
  private progress = 0;
  private eased = 0;
  private clock = 0;
  private last = 0;
  private readonly still: boolean;
  private readonly quality: 'high' | 'low';
  private width: number;
  private height: number;
  private pixelRatio: number;
  private readonly onGame?: (game: Game) => void;

  /** Where in the three games we are. */
  private gameIndex = 0;
  private plyIndex = 0;
  private wait = FIRST_MOVE_DELAY;

  /** Resolves once the first frame has actually been painted. */
  readonly ready: Promise<void>;
  private markReady!: () => void;

  constructor(
    private readonly canvas: HTMLCanvasElement | OffscreenCanvas,
    options: TitleSequenceOptions,
  ) {
    this.quality = options.quality ?? 'high';
    this.still = options.still ?? false;
    this.onGame = options.onGame;
    this.onPainted = options.onPainted;
    this.width = options.width;
    this.height = options.height;
    this.pixelRatio = options.pixelRatio;
    this.ready = new Promise<void>((resolve) => (this.markReady = resolve));

    this.renderer = new WebGLRenderer({
      canvas,
      antialias: this.quality === 'high',
      // Transparent, deliberately. The poster sits behind this canvas, and if
      // the scene ever fails to present a frame — a driver quirk, a worker
      // that cannot composite — an opaque clear colour would replace a good
      // still with a black rectangle. This way the worst case is the poster.
      alpha: true,
      powerPreference: 'high-performance',
      stencil: false,
    });
    this.renderer.outputColorSpace = SRGBColorSpace;
    this.renderer.toneMapping = ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.0;
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = PCFShadowMap;
    // Dropping clearcoat and sheen on the low tier was tried here and made no
    // measurable difference — 2.3s of script evaluation either way, across
    // three runs — so the pieces keep their polish on a phone. What follows is
    // what actually moved the number.
    //
    // On the low tier the shadow map is redrawn by hand, every other frame.
    // It is a second pass over the whole board and it is the most expensive
    // thing in the loop; at fifteen hertz, on a shot where the only thing
    // moving is one piece gliding a square and a half, nobody can tell.
    this.renderer.shadowMap.autoUpdate = this.quality === 'high';
    this.renderer.setClearColor(0x04050c, 0);

    this.camera = new PerspectiveCamera(38, 1, 0.1, 120);
    // The same colour the renderer clears to, so the floor's far edge and the
    // empty frame above it are the same nothing.
    this.scene.fog = new Fog(0x04050c, 11, 32);

    // Everything expensive happens in build(), which yields between phases.
  }

  /**
   * Assembles the scene, giving the browser a gap between each phase.
   *
   * Built all at once this is a single task of several hundred milliseconds —
   * one lathe per piece, two canvas textures, an environment map — and a task
   * that long is a page that does not answer a tap. Split across phases it is
   * the same total work in pieces short enough for the browser to interrupt,
   * which is the difference the metric is actually measuring.
   */
  static async create(
    canvas: HTMLCanvasElement | OffscreenCanvas,
    options: TitleSequenceOptions,
  ): Promise<TitleSequence> {
    const sequence = new TitleSequence(canvas, options);
    await sequence.build();
    return sequence;
  }

  private async build(): Promise<void> {
    this.buildEnvironment();
    await pause();

    this.buildFloor();
    this.buildBoard();
    await pause();

    // Six lathes, one per phase. Each is tens of milliseconds; together they
    // are the longest single stretch in the whole build.
    const geometries = {} as Record<PieceKind, BufferGeometry>;
    for (const kind of PIECE_KINDS) {
      geometries[kind] = buildPieceGeometry(kind);
      await pause();
    }
    this.play = this.buildPieces(geometries);
    await pause();

    this.keyLight = this.buildLights();

    // A practical that travels with the move. It is the cheapest way to make a
    // board full of identical objects tell you where to look.
    this.practical = new PointLight(0xffc27a, 3.4, 5.2, 2);
    this.practical.position.set(0, 0.45, 0);
    this.scene.add(this.practical);

    this.dust = this.buildDust();
    await pause();

    if (this.quality === 'high' && !this.still) {
      const composer = new EffectComposer(this.renderer);
      composer.addPass(new RenderPass(this.scene, this.camera));
      const bloom = new UnrealBloomPass(
        new Vector2(1, 1),
        0.28, // strength — a sheen on the brass, not a glow stick
        0.85, // radius
        0.86, // threshold: only the highlights
      );
      composer.addPass(bloom);
      composer.addPass(new OutputPass());
      this.composer = composer;
      this.bloom = bloom;
      this.disposables.push(composer);
    }

    this.resize();
    this.apply(0);

    // Shader compilation is the single longest task in the whole startup —
    // physical materials with clearcoat, shadows and a bloom pass add up to a
    // lot of GLSL, and by default all of it is compiled inside the first frame.
    // compileAsync hands it to the driver ahead of time and, where
    // KHR_parallel_shader_compile exists, off the main thread entirely.
    // Raced against a timeout rather than simply awaited. Compilation
    // readiness is reported through KHR_parallel_shader_compile, and a driver
    // that never flips that flag would leave this promise pending forever —
    // which, with the poster underneath, is a hero that silently never
    // arrives. Losing the head start is a far smaller cost than that.
    await Promise.race([
      this.renderer.compileAsync(this.scene, this.camera),
      new Promise((resolve) => setTimeout(resolve, 1500)),
    ]);

    // Announce the opening game before the first frame, so the caption is
    // never a beat behind the board.
    this.onGame?.(GAMES[0]);
  }

  // ── Construction ────────────────────────────────────────────────────────

  private buildEnvironment(): void {
    // Something for the metal to reflect, and nothing more than that.
    //
    // three's RoomEnvironment is the usual answer and it builds a whole scene
    // of boxes and area lights to photograph. At the blur this is used at —
    // 0.06, effectively total — none of that survives; a sixteen-pixel gradient
    // produces the same reflection for a fraction of the startup cost.
    const strip = scratch(8, 32);
    const ctx = strip.getContext('2d') as Canvas2D;
    // Bright at the top, because this stands in for a lit ceiling rather than
    // for the night sky the camera is actually in. An environment map that is
    // as dark as the scene reflects nothing, and the ivory loses its sheen.
    const sky = ctx.createLinearGradient(0, 0, 0, 32);
    sky.addColorStop(0, '#fff6e6');
    sky.addColorStop(0.35, '#c8c2b4');
    sky.addColorStop(0.52, '#5c6070');
    sky.addColorStop(0.7, '#22262f');
    sky.addColorStop(1, '#0a0b10');
    ctx.fillStyle = sky;
    ctx.fillRect(0, 0, 8, 32);

    const equirect = new CanvasTexture(strip as HTMLCanvasElement);
    equirect.mapping = EquirectangularReflectionMapping;
    equirect.colorSpace = SRGBColorSpace;

    const pmrem = new PMREMGenerator(this.renderer);
    this.scene.environment = pmrem.fromEquirectangular(equirect).texture;
    // A tenth, not the quarter RoomEnvironment wanted. This gradient is bright
    // across the whole upper hemisphere where the room was mostly dark with a
    // few lit panels, so the same number here is several times the fill light —
    // enough to flatten the key light's contrast into an evenly lit board.
    this.scene.environmentIntensity = 0.1;
    equirect.dispose();
    pmrem.dispose();
  }

  private buildFloor(): void {
    const geometry = new PlaneGeometry(200, 200);
    const material = new MeshStandardMaterial({
      color: 0x02030a,
      roughness: 0.95,
      metalness: 0.0,
    });
    const floor = new Mesh(geometry, material);
    floor.rotation.x = -Math.PI / 2;
    floor.position.y = -0.26;
    floor.receiveShadow = true;
    this.scene.add(floor);
    this.disposables.push(geometry, material);
  }

  private buildBoard(): void {
    const { map, roughness } = boardTexture(this.quality === 'high' ? 1024 : 512);

    const top = new BoxGeometry(8, 0.001, 8);
    const surface = new Mesh(
      top,
      new MeshPhysicalMaterial({
        map,
        roughnessMap: roughness,
        roughness: 0.42,
        metalness: 0.0,
        clearcoat: 0.55,
        clearcoatRoughness: 0.22,
      }),
    );
    surface.position.y = 0.0;
    surface.receiveShadow = true;

    // The plinth the board sits on, in the same ebony as the black pieces.
    const plinthGeometry = new BoxGeometry(9.1, 0.25, 9.1);
    const plinthMaterial = new MeshPhysicalMaterial({
      color: 0x0e1017,
      roughness: 0.34,
      metalness: 0.12,
      clearcoat: 0.7,
      clearcoatRoughness: 0.25,
    });
    const plinth = new Mesh(plinthGeometry, plinthMaterial);
    plinth.position.y = -0.126;
    plinth.castShadow = true;
    plinth.receiveShadow = true;

    this.board.add(surface, plinth);
    this.scene.add(this.board);
    this.disposables.push(map, roughness, top, plinthGeometry, plinthMaterial, surface.material);
  }

  private buildPieces(geometries: Record<PieceKind, BufferGeometry>): PlayingBoard {
    const ivory = new MeshPhysicalMaterial({
      color: new Color(0xe6dfcd),
      roughness: 0.36,
      metalness: 0.0,
      clearcoat: 0.55,
      clearcoatRoughness: 0.3,
      sheen: 0.35,
      sheenColor: new Color(0xfff4dd),
    });
    const ebony = new MeshPhysicalMaterial({
      color: new Color(0x11131a),
      roughness: 0.3,
      metalness: 0.08,
      clearcoat: 0.75,
      clearcoatRoughness: 0.18,
    });

    // The piece that is moving wears a warmed version of its own colour. Not a
    // different piece in gold — the same piece, catching the light, which is
    // what a hand lifting it off the board would actually look like.
    const ivoryLit = ivory.clone();
    ivoryLit.emissive = new Color(0xd6a95f);
    ivoryLit.emissiveIntensity = 0.42;
    const ebonyLit = ebony.clone();
    ebonyLit.emissive = new Color(0xd6a95f);
    ebonyLit.emissiveIntensity = 0.7;

    const play = new PlayingBoard(geometries, { ivory, ebony, ivoryLit, ebonyLit });
    this.scene.add(play.group);

    this.disposables.push(ivory, ebony, ivoryLit, ebonyLit, ...Object.values(geometries));
    return play;
  }

  private buildLights(): SpotLight {
    const shadowSize = this.quality === 'high' ? 2048 : 1024;

    // The key: a single hard warm source, high and behind the black king, so
    // the pieces throw their shadows down the board toward the viewer.
    //
    // The intensities look enormous because three.js lights are physical: a
    // point source is in candela and falls off with the square of the distance,
    // and this one is roughly eleven units up. Divide by 121 before judging it.
    const key = new SpotLight(0xffcf94, 420, 36, Math.PI / 6.8, 0.4, 2);
    key.position.set(6.5, 8.5, -5.0);
    key.target.position.set(0.8, 0, -1.2);
    key.castShadow = true;
    key.shadow.mapSize.set(shadowSize, shadowSize);
    key.shadow.bias = -0.0012;
    key.shadow.normalBias = 0.022;
    key.shadow.camera.near = 1;
    key.shadow.camera.far = 30;
    this.scene.add(key, key.target);

    // The rim: cold, low, from the far side. It is what keeps the black pieces
    // from disappearing into a black room.
    const rim = new SpotLight(0x5d84c6, 110, 36, Math.PI / 4.6, 0.85, 2);
    rim.position.set(-8.5, 3.2, -6.0);
    rim.target.position.set(0, 0.3, 0);
    this.scene.add(rim, rim.target);

    const fill = new DirectionalLight(0x8ea6cc, 0.08);
    fill.position.set(-3, 4, 8);
    this.scene.add(fill);

    this.scene.add(new AmbientLight(0x141b2c, 0.3));

    return key;
  }

  private buildDust(): Points {
    const count = this.quality === 'high' ? 520 : 220;
    const positions = new Float32Array(count * 3);
    const drift = new Float32Array(count);

    for (let i = 0; i < count; i++) {
      positions[i * 3] = (Math.random() - 0.5) * 22;
      positions[i * 3 + 1] = Math.random() * 8;
      positions[i * 3 + 2] = (Math.random() - 0.5) * 22;
      drift[i] = 0.04 + Math.random() * 0.16;
    }

    const geometry = new BufferGeometry();
    geometry.setAttribute('position', new BufferAttribute(positions, 3));
    geometry.setAttribute('aDrift', new BufferAttribute(drift, 1));

    const map = dustTexture();
    const material = new PointsMaterial({
      size: 0.055,
      map,
      transparent: true,
      opacity: 0.34,
      depthWrite: false,
      blending: AdditiveBlending,
      color: 0xf3e2c0,
      sizeAttenuation: true,
    });

    const points = new Points(geometry, material);
    this.scene.add(points);
    this.disposables.push(geometry, material, map);
    return points;
  }

  // ── Driving it ──────────────────────────────────────────────────────────

  /** True while the animation loop is scheduled. */
  get isRunning(): boolean {
    return this.running;
  }

  /** Scroll position through the hero, 0 at the top and 1 at the bottom. */
  setProgress(value: number): void {
    this.progress = Math.min(1, Math.max(0, value));
  }

  start(): void {
    if (this.running) return;
    this.running = true;
    this.last = performance.now();
    // Thirty frames a second on a phone, sixty on everything else.
    //
    // The shot is a slow drift and a piece settling; there is nothing in it
    // that thirty frames cannot carry. What sixty costs is a second render of
    // the whole board into the shadow map, a pass over every dust particle and
    // a buffer upload, all of it twice as often as anyone can see — and on a
    // mid-range phone that was most of the page's blocking time.
    const minFrame = this.quality === 'low' ? 1000 / 31 : 0;

    const tick = (now: number) => {
      if (!this.running) return;
      this.frame = requestAnimationFrame(tick);

      // `last` is deliberately not moved on a skipped frame: the time still
      // passed, and the next real frame has to advance the scene by all of it
      // or the sequence plays slowly on exactly the devices that skip most.
      if (now - this.last < minFrame) return;

      const delta = Math.min((now - this.last) / 1000, 0.05);
      this.last = now;
      this.clock += delta;
      this.update(delta);
      this.render();
    };
    this.frame = requestAnimationFrame(tick);
  }

  stop(): void {
    this.running = false;
    if (this.frame) cancelAnimationFrame(this.frame);
    this.frame = 0;
  }

  /** Renders one frame without starting the loop. */
  renderStill(): void {
    this.apply(this.progress);
    this.render();
  }

  private update(delta: number): void {
    // The camera lags the scroll, which is what stops a scroll-driven shot
    // from feeling like a slider being dragged.
    this.eased += (this.progress - this.eased) * Math.min(1, delta * 3.4);
    this.apply(this.eased);

    // Dust rises and wraps, so the light always has something crossing it.
    const positions = this.dust.geometry.getAttribute('position') as BufferAttribute;
    const drift = this.dust.geometry.getAttribute('aDrift') as BufferAttribute;
    for (let i = 0; i < positions.count; i++) {
      let y = positions.getY(i) + drift.getX(i) * delta;
      if (y > 8) y = 0;
      positions.setY(i, y);
      positions.setX(i, positions.getX(i) + Math.sin(this.clock * 0.28 + i) * delta * 0.014);
    }
    positions.needsUpdate = true;

    this.advance(delta);

    // The key light breathes, very slightly. A perfectly steady light reads as
    // a render; a moving one reads as a room.
    this.keyLight.intensity = 420 + Math.sin(this.clock * 0.7) * 22;

    if (this.bloom) {
      // Bloom opens up as the shot pulls back, so the wide is the pretty one.
      this.bloom.strength = 0.24 + this.eased * 0.2;
    }
  }

  /**
   * Plays the games. One move at a time, waiting for the pieces to settle
   * before starting the clock on the next — so a slow machine gets a slower
   * game rather than a pile-up.
   */
  private advance(delta: number): void {
    this.play.update(delta);
    this.practical.position.copy(this.play.focus);

    if (!this.play.idle) return;

    this.wait -= delta;
    if (this.wait > 0) return;

    const game = GAMES[this.gameIndex];

    if (this.plyIndex >= game.plies.length) {
      // Let the mate stand for a moment before clearing the board.
      this.gameIndex = (this.gameIndex + 1) % GAMES.length;
      this.plyIndex = 0;
      this.play.reset();
      this.wait = FIRST_MOVE_DELAY;
      this.onGame?.(GAMES[this.gameIndex]);
      return;
    }

    this.play.play(game.plies[this.plyIndex]);
    this.plyIndex += 1;
    this.wait = this.plyIndex >= game.plies.length ? AFTER_MATE : BETWEEN_MOVES;
  }

  /** Places the camera for a given point in the sequence. */
  private apply(t: number): void {
    const eye = EYE.getPoint(t);
    const target = TARGET.getPoint(t);

    // A slow handheld float, scaled down as the shot widens.
    const sway = (1 - t * 0.6) * 0.055;
    eye.x += Math.sin(this.clock * 0.42) * sway;
    eye.y += Math.sin(this.clock * 0.31 + 1.2) * sway * 0.7;

    this.camera.position.copy(eye);
    this.camera.lookAt(target);
    // A whisper of roll, the way a shoulder-mounted camera never sits level.
    this.camera.rotation.z += Math.sin(this.clock * 0.23) * 0.006 * (1 - t);
  }

  private frameCount = 0;
  /** Called once the loop has produced a few frames. Proof of life. */
  private readonly onPainted?: () => void;

  private render(): void {
    this.frameCount++;
    if (this.frameCount === 3) this.onPainted?.();
    if (!this.renderer.shadowMap.autoUpdate) {
      // The first two frames always, so the opening image is not shadowless.
      this.renderer.shadowMap.needsUpdate = this.frameCount < 3 || this.frameCount % 2 === 0;
    }
    // Checked every frame rather than trusted to an event. Between a hidden
    // tab reporting no size, a device-pixel-ratio change on a monitor switch
    // and an element that resizes without the window doing so, comparing the
    // drawing buffer to the element is the only check that is never wrong —
    // and it costs two integer comparisons.
    this.syncSize();

    if (this.composer) this.composer.render();
    else this.renderer.render(this.scene, this.camera);

    this.markReady();
  }

  /** Resizes only when the drawing buffer and the requested size disagree. */
  private syncSize(): void {
    if (this.width < 2 || this.height < 2) return;
    const dpr = this.clampRatio();
    if (
      this.canvas.width !== Math.round(this.width * dpr) ||
      this.canvas.height !== Math.round(this.height * dpr)
    ) {
      this.resize();
    }
  }

  private clampRatio(): number {
    return Math.min(this.pixelRatio || 1, this.quality === 'high' ? 1.75 : 1.25);
  }

  /** Tells the scene how big it is now. Nothing here measures anything. */
  resize(width = this.width, height = this.height, pixelRatio = this.pixelRatio): void {
    this.width = width;
    this.height = height;
    this.pixelRatio = pixelRatio;

    // Nothing to draw into yet — a hidden tab reports zero, and pinning the
    // renderer to a single pixel for the session is how that used to end.
    if (width < 2 || height < 2) return;

    const dpr = this.clampRatio();
    this.renderer.setPixelRatio(dpr);
    this.renderer.setSize(width, height, false);
    this.composer?.setPixelRatio(dpr);
    this.composer?.setSize(width, height);

    this.camera.aspect = width / height;
    // On a tall phone the board falls out of frame; widening the lens keeps the
    // composition rather than the focal length.
    this.camera.fov = this.camera.aspect < 0.9 ? 54 : 38;
    this.camera.updateProjectionMatrix();
  }

  dispose(): void {
    this.stop();
    for (const item of this.disposables) item.dispose();
    this.scene.clear();
    this.renderer.dispose();
    this.renderer.forceContextLoss();
  }
}
