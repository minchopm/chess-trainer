import {
  ACESFilmicToneMapping,
  AdditiveBlending,
  AmbientLight,
  BoxGeometry,
  BufferGeometry,
  CanvasTexture,
  Color,
  DirectionalLight,
  EquirectangularReflectionMapping,
  Fog,
  Group,
  Material,
  Mesh,
  MeshBasicMaterial,
  MeshPhysicalMaterial,
  MeshStandardMaterial,
  Object3D,
  PCFShadowMap,
  PerspectiveCamera,
  PlaneGeometry,
  PMREMGenerator,
  Scene,
  SpotLight,
  SRGBColorSpace,
  Texture,
  Vector3,
  WebGLRenderer,
} from 'three';

import { RoundedBoxGeometry } from 'three/examples/jsm/geometries/RoundedBoxGeometry.js';

import { boardTexture, Canvas2D, scratch } from '../three/board';
import { squareToPosition } from '../three/board-play';
import { buildParlourGeometries, PARLOUR_HEIGHT } from '../three/parlour-set';
import { buildPieceGeometries, PieceKind } from '../three/pieces';
import { BoardConfig, Carving } from './config';
import type { Position2D } from './draw2d';
import { letters, parlourRoom } from './parlour';

const KINDS: Record<string, PieceKind> = { k: 'king', q: 'queen', r: 'rook', b: 'bishop', n: 'knight', p: 'pawn' };

/** A room a set is shown in: what stands in it, what lights it, and how much of it the camera must keep. */
interface Room {
  readonly group: Group;
  readonly lights: Object3D[];
  readonly environment: Texture;
  readonly environmentIntensity: number;
  readonly fog: Fog | null;
  /** What the room clears to; the theatre leaves it to the page. */
  readonly background: Color | null;
  /** The files and ranks round the squares, switched with the reader's Coordinates. */
  readonly coordinates: Mesh;
  /**
   * What the camera must keep in frame: the plinth's or the frame's half-width,
   * its top and bottom, and the tallest piece of the set that stands in it.
   */
  readonly bounds: { readonly half: number; readonly top: number; readonly bottom: number; readonly pieces: number };
}

/** A set: one geometry per kind, and what each side is made of. */
interface Turned {
  readonly geometries: Record<PieceKind, BufferGeometry>;
  readonly light: Material[];
  readonly dark: Material[];
}

/**
 * The round board, for one position: LiveBoard's room, holding still.
 *
 * Built from the reader's settings the way the app builds its scene from the
 * player's — and from the same settings the app reads for it, which is one:
 * the set. In the app the flat board's squares, stains and light tones stop
 * at the flat board; in the round the board is the room's own, and the set
 * decides the room. So it is here. Nothing is downloaded for it that the flat
 * board did not already need, which is nothing at all, and it renders when
 * something changes and not otherwise: a page of text with a board in it has
 * no business spinning a GPU at sixty frames a second.
 */
export class Board3D {
  private readonly renderer: WebGLRenderer;
  private readonly scene = new Scene();
  // The app's lens, which never changes — OrbitCamera.fieldOfView. The camera
  // moves instead, so every size of board sees the same perspective.
  private readonly camera = new PerspectiveCamera(52, 1, 0.1, 120);
  private readonly white: Mesh[] = [];
  private readonly black: Mesh[] = [];
  private readonly marks: Mesh[] = [];
  private readonly disposables: { dispose(): void }[] = [];

  private readonly theatre: Room;
  private readonly banded: Turned;
  private readonly plain: Turned;
  /** The walnut set and its room: a table, a frame and a lamp, built the first time somebody asks for them. */
  private parlour: { room: Room; set: Turned } | null = null;
  private room: Room | null = null;
  private turned: Turned | null = null;

  /** Where the camera stands, round the board and above it. */
  private azimuth = 0;
  private elevation = 0.95;
  private flip = false;
  private frame = 0;
  private size = { width: 0, height: 0 };

  constructor(private readonly canvas: HTMLCanvasElement) {
    this.renderer = new WebGLRenderer({ canvas, antialias: true, alpha: true });
    this.renderer.setPixelRatio(Math.min(2, window.devicePixelRatio || 1));
    this.renderer.toneMapping = ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = Board3D.exposure;
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = PCFShadowMap;

    this.theatre = this.buildTheatre();

    const geometries = buildPieceGeometries();
    const ivory = new MeshPhysicalMaterial({
      color: new Color(0xe8dcc0),
      roughness: 0.36,
      clearcoat: 0.55,
      clearcoatRoughness: 0.3,
      sheen: 0.35,
      sheenColor: new Color(0xfff4dd),
    });
    const ebony = new MeshPhysicalMaterial({
      color: new Color(0x14161c),
      roughness: 0.3,
      metalness: 0.08,
      clearcoat: 0.75,
      clearcoatRoughness: 0.18,
    });
    const brass = new MeshPhysicalMaterial({ color: new Color(0xd9ac61), roughness: 0.28, metalness: 0.78 });
    // The plain set is the banded one without its brass — the same turning,
    // and nothing on it — so the trim's draw range is simply not drawn.
    const bare = new MeshBasicMaterial({ visible: false });
    this.banded = { geometries, light: [ivory, brass], dark: [ebony, brass] };
    this.plain = { geometries, light: [ivory, bare], dark: [ebony, bare] };
    this.disposables.push(ivory, ebony, brass, bare, ...Object.values(geometries));

    // Sixteen of each side: no position has more, and a promoted piece is a
    // pawn's mesh wearing another geometry.
    for (let i = 0; i < 16; i++) {
      this.white.push(this.piece());
      this.black.push(this.piece());
    }

    // Highlights.trail: the squares the last move left and reached, in brass
    // light added to whatever is under them rather than painted over it.
    const markGeometry = new PlaneGeometry(0.98, 0.98);
    const markMaterial = new MeshBasicMaterial({
      color: 0xd6a95f,
      transparent: true,
      opacity: 0.16,
      blending: AdditiveBlending,
      depthWrite: false,
    });
    for (let i = 0; i < 2; i++) {
      const mark = new Mesh(markGeometry, markMaterial);
      mark.rotation.x = -Math.PI / 2;
      mark.renderOrder = 10;
      mark.visible = false;
      this.marks.push(mark);
      this.scene.add(mark);
    }
    this.disposables.push(markMaterial, markGeometry);

    this.dragToTurn();
  }

  /** Set the position and the set, and draw it. */
  show(position: Position2D, config: BoardConfig): void {
    this.dress(config.carving);
    this.room!.coordinates.visible = config.coordinates;

    if (!!position.flip !== this.flip || this.frame === 0) {
      this.flip = !!position.flip;
      this.azimuth = this.flip ? Math.PI : 0;
    }

    const set = this.turned!;
    const rows = position.fen.split(' ')[0].split('/');
    let w = 0;
    let b = 0;
    for (const mesh of [...this.white, ...this.black]) mesh.visible = false;
    for (let r = 0; r < 8; r++) {
      let file = 0;
      for (const ch of rows[r] ?? '') {
        if (/\d/.test(ch)) {
          file += Number(ch);
          continue;
        }
        const isWhite = ch === ch.toUpperCase();
        const mesh = isWhite ? this.white[w++] : this.black[b++];
        if (mesh) {
          mesh.geometry = set.geometries[KINDS[ch.toLowerCase()]];
          mesh.material = isWhite ? set.light : set.dark;
          squareToPosition(String.fromCharCode(97 + file) + (8 - r), mesh.position);
          // Knights face the other side, as the title board sets them.
          mesh.rotation.y = isWhite ? Math.PI : 0;
          mesh.visible = true;
        }
        file++;
      }
    }

    const squares = position.last ? [position.last.from, position.last.to] : [];
    this.marks.forEach((mark, i) => {
      mark.visible = !!squares[i];
      if (squares[i]) squareToPosition(squares[i], mark.position).setY(0.004);
    });
    this.render();
  }

  /** The drawing buffer's size; the next `show` draws at it. */
  resize(width: number, height: number): void {
    if (width === this.size.width && height === this.size.height) return;
    this.size = { width, height };
    this.renderer.setSize(width, height, false);
    this.camera.aspect = width / height;
  }

  dispose(): void {
    for (const item of this.disposables) item.dispose();
    this.renderer.dispose();
  }

  /**
   * The room and the set for this carving — Carving.style and
   * PieceStyle.dressing: the board follows the set rather than being a second
   * thing to choose, because the walnut set in the black room reads as a
   * different game and the brass has nothing to catch under a lamp.
   */
  private dress(carving: Carving): void {
    let room = this.theatre;
    let set = carving === 'banded' ? this.banded : this.plain;
    if (carving === 'parlour') {
      this.parlour ??= this.buildParlour();
      ({ room, set } = this.parlour);
    }
    this.turned = set;
    if (room === this.room) return;
    if (this.room) {
      this.scene.remove(this.room.group, ...this.room.lights);
    }
    this.room = room;
    this.scene.add(room.group, ...room.lights);
    this.scene.environment = room.environment;
    this.scene.environmentIntensity = room.environmentIntensity;
    this.scene.fog = room.fog;
    this.scene.background = room.background;
  }

  private buildParlour(): { room: Room; set: Turned } {
    const parlour = parlourRoom(this.renderer);
    const geometries = buildParlourGeometries();
    this.disposables.push(parlour, ...Object.values(geometries));
    return {
      room: {
        ...parlour,
        bounds: { ...parlour.bounds, pieces: PARLOUR_HEIGHT },
      },
      // One group per piece: no brass anywhere on it.
      set: { geometries, light: [parlour.light], dark: [parlour.dark] },
    };
  }

  private render(): void {
    this.frame++;
    const { distance, shift } = this.fit();
    this.place(distance);
    // The lens moved rather than the camera turned: the fitted board is centred
    // in the frame without changing the angle it is seen from.
    this.camera.updateProjectionMatrix();
    this.camera.projectionMatrix.elements[8] = shift.x;
    this.camera.projectionMatrix.elements[9] = shift.y;
    this.camera.projectionMatrixInverse.copy(this.camera.projectionMatrix).invert();
    this.renderer.render(this.scene, this.camera);
  }

  private place(distance: number): void {
    const target = Board3D.target;
    this.camera.position.set(
      target.x + Math.sin(this.azimuth) * Math.cos(this.elevation) * distance,
      target.y + Math.sin(this.elevation) * distance,
      target.z + Math.cos(this.azimuth) * Math.cos(this.elevation) * distance,
    );
    this.camera.lookAt(target);
    this.camera.updateMatrixWorld();
  }

  /**
   * OrbitCamera.reframe: the distance solved by halving, not estimated — the
   * near corner projects far larger than the far one and the answer moves with
   * every angle and every aspect. What has to fit is the room's field, and the
   * tops of the tallest pieces on the back ranks, so a king there is never cut
   * off and the frame does not breathe as the pieces move.
   */
  private fit(): { distance: number; shift: { x: number; y: number } } {
    const { half, top, bottom, pieces } = this.room!.bounds;
    const corners: [number, number, number][] = [];
    for (const x of [-1, 1]) {
      for (const z of [-1, 1]) {
        // A back-rank corner piece's top: the square's centre and a king's foot out from it.
        corners.push([x * half, top, z * half], [x * half, bottom, z * half], [x * 3.9, pieces, z * 3.9]);
      }
    }
    const halfVertical = Math.tan((this.camera.fov * Math.PI) / 360);
    const halfHorizontal = halfVertical * this.camera.aspect;
    const point = new Vector3();
    const extent = (distance: number) => {
      this.place(distance);
      const view = this.camera.matrixWorldInverse;
      let left = Infinity, right = -Infinity, low = Infinity, high = -Infinity;
      for (const [x, y, z] of corners) {
        point.set(x, y, z).applyMatrix4(view);
        const depth = -point.z;
        if (depth < 0.01) return null;
        const u = point.x / (depth * halfHorizontal);
        const v = point.y / (depth * halfVertical);
        left = Math.min(left, u); right = Math.max(right, u);
        low = Math.min(low, v); high = Math.max(high, v);
      }
      return { left, right, low, high };
    };
    let tooClose = 6;
    let farEnough = 40;
    for (let i = 0; i < 24; i++) {
      const middle = (tooClose + farEnough) / 2;
      const e = extent(middle);
      const reach = e ? Math.max(e.right - e.left, e.high - e.low) / 2 : Infinity;
      if (reach > Board3D.allowed) tooClose = middle;
      else farEnough = middle;
    }
    const e = extent(farEnough)!;
    return { distance: farEnough, shift: { x: (e.left + e.right) / 2, y: (e.low + e.high) / 2 } };
  }

  /** LiveBoard's aim: the middle of the board, a little above the squares. */
  private static readonly target = new Vector3(0, 0.2, 0);
  /** How far across the frame the board may reach, where 1 is the edge. */
  private static readonly allowed = 0.95;
  /**
   * The app's exposure against the site's renderer. SceneKit's filmic curve
   * and the ACES one here do not agree about the middle, and at 1 the same
   * lights leave every square a third darker than the app's; this is the
   * stop and a half that puts the squares and the boxwood where the app has
   * them, measured against the app's own renders.
   */
  private static readonly exposure = 1.5;

  private piece(): Mesh {
    const mesh = new Mesh(this.banded.geometries.pawn, this.banded.light);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    mesh.visible = false;
    this.scene.add(mesh);
    return mesh;
  }

  /**
   * The black room the app opens on, as LiveBoard lights it: Stage with
   * `playable` on — the title's board, plinth and lights, turned down from a
   * shot to a board somebody has to read.
   */
  private buildTheatre(): Room {
    const group = new Group();

    // The squares: the title board's two woods under its drawn grain. The
    // app's field is 0.02 thick and stands 0.004 proud of the plinth it is set
    // into; lifted so its top is at y = 0.
    const { map, roughness } = boardTexture(1024);
    const top = new BoxGeometry(8, 0.02, 8);
    const surface = new MeshPhysicalMaterial({
      map,
      roughnessMap: roughness,
      // The map is the roughness, as SceneKit reads it; three.js multiplies
      // the two, and anything under one here is a glossier board than the app's.
      roughness: 1,
      // The playing board's varnish, not the title's: low and rough, so the
      // key light is a sheen and not a white pool an ivory piece vanishes in.
      clearcoat: 0.1,
      clearcoatRoughness: 0.68,
    });
    const field = new Mesh(top, surface);
    field.position.y = -0.01;
    field.receiveShadow = true;

    // The ebony plinth and the dark floor it stands on.
    const plinthGeometry = new RoundedBoxGeometry(9.1, 0.25, 9.1, 2, 0.02);
    const plinthMaterial = new MeshPhysicalMaterial({
      color: 0x0e1017,
      roughness: 0.34,
      metalness: 0.12,
      clearcoat: 0.7,
      clearcoatRoughness: 0.25,
    });
    const plinth = new Mesh(plinthGeometry, plinthMaterial);
    plinth.position.y = -0.017 - 0.125;
    plinth.receiveShadow = true;
    const floorGeometry = new PlaneGeometry(200, 200);
    const floorMaterial = new MeshStandardMaterial({ color: 0x02030a, roughness: 0.95 });
    const floor = new Mesh(floorGeometry, floorMaterial);
    floor.rotation.x = -Math.PI / 2;
    floor.position.y = -0.256;
    floor.receiveShadow = true;

    // The files and ranks on the plinth: BoardSurface.coordinates, unlit, so
    // they read as well in the corner the key does not reach as under it.
    const ink = new CanvasTexture(letters(1024, 'rgba(235, 224, 199, 0.62)') as HTMLCanvasElement);
    ink.colorSpace = SRGBColorSpace;
    ink.anisotropy = Math.min(8, this.renderer.capabilities.getMaxAnisotropy());
    const paintGeometry = new PlaneGeometry(9.1, 9.1);
    const paint = new MeshBasicMaterial({ map: ink, transparent: true, depthWrite: false });
    const coordinates = new Mesh(paintGeometry, paint);
    coordinates.rotation.x = -Math.PI / 2;
    coordinates.position.y = -0.0155;

    group.add(field, plinth, floor, coordinates);
    this.disposables.push(
      top, surface, map, roughness, plinthGeometry, plinthMaterial, floorGeometry, floorMaterial,
      ink, paintGeometry, paint,
    );

    const environment = this.gradientEnvironment();
    return {
      group,
      lights: this.theatreLights(),
      environment,
      environmentIntensity: 0.1,
      fog: null,
      background: null,
      coordinates,
      bounds: { half: 4.55, top: -0.017, bottom: -0.267, pieces: 1.44 },
    };
  }

  /** TitleSequence.buildEnvironment: a gradient for the brass and the lacquer to reflect. */
  private gradientEnvironment(): Texture {
    const strip = scratch(8, 32);
    const ctx = strip.getContext('2d') as Canvas2D;
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
    const environment = pmrem.fromEquirectangular(equirect).texture;
    equirect.dispose();
    pmrem.dispose();
    this.disposables.push(environment);
    return environment;
  }

  /**
   * Stage.buildLights with `playable` on: the warm key behind the far side,
   * wide and soft and aimed at the middle, the cold rim, the fill and a lifted
   * ambient — the room turned down from a title shot to a board being read.
   */
  private theatreLights(): Object3D[] {
    // SceneKit's cone is 34°/78° across; three.js takes half the outer angle
    // and the soft part as a fraction of it.
    const key = new SpotLight(0xffcf94, 290, 36, (39 * Math.PI) / 180, 1 - 17 / 39, 2);
    key.position.set(6.5, 8.5, -5.0);
    key.target.position.set(0, 0, -0.3);
    key.castShadow = true;
    key.shadow.mapSize.set(2048, 2048);
    key.shadow.bias = -0.0012;
    key.shadow.normalBias = 0.022;
    key.shadow.camera.near = 1;
    key.shadow.camera.far = 30;
    // The app's rim colour, not the title's bluer one: the shadows on the
    // squares take it, and 0x5d84c6 left them cold where the app's are grey.
    const rim = new SpotLight(0x7c93b8, 123, 36, (39 * Math.PI) / 180, 1 - 15 / 39, 2);
    rim.position.set(-8.5, 3.2, -6.0);
    rim.target.position.set(0, 0.3, 0);
    const fill = new DirectionalLight(0x8ea6cc, 0.65);
    fill.position.set(-3, 6, 8);
    this.disposables.push({ dispose: () => key.shadow.dispose() });
    return [key, key.target, rim, rim.target, fill, new AmbientLight(0x2a3246, 1.6)];
  }

  /** Drag to walk round the board, as the app's round board turns under a finger. */
  private dragToTurn(): void {
    let last: { x: number; y: number } | null = null;
    this.canvas.style.touchAction = 'pan-y';
    this.canvas.addEventListener('pointerdown', (event) => {
      last = { x: event.clientX, y: event.clientY };
      this.canvas.setPointerCapture(event.pointerId);
    });
    this.canvas.addEventListener('pointermove', (event) => {
      if (!last) return;
      this.azimuth -= (event.clientX - last.x) * 0.008;
      this.elevation = Math.min(1.45, Math.max(0.45, this.elevation + (event.clientY - last.y) * 0.005));
      last = { x: event.clientX, y: event.clientY };
      this.render();
    });
    const end = () => (last = null);
    this.canvas.addEventListener('pointerup', end);
    this.canvas.addEventListener('pointercancel', end);
  }
}
