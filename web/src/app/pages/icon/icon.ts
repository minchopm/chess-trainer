import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  afterNextRender,
  viewChild,
} from '@angular/core';
import {
  ACESFilmicToneMapping,
  AmbientLight,
  BoxGeometry,
  CanvasTexture,
  Color,
  EquirectangularReflectionMapping,
  Fog,
  Mesh,
  MeshPhysicalMaterial,
  MeshStandardMaterial,
  PCFShadowMap,
  PMREMGenerator,
  PerspectiveCamera,
  PlaneGeometry,
  PointLight,
  SRGBColorSpace,
  Scene,
  SpotLight,
  WebGLRenderer,
} from 'three';

import { boardTexture } from '../../three/board';
import { buildPieceGeometry } from '../../three/pieces';

/**
 * The app icon, rendered rather than drawn.
 *
 * Same geometry and the same lights as the title sequence, so the thing on the
 * home screen is literally a still from the film — and re-rendering it after a
 * change to the pieces is a screenshot rather than a trip to a design tool.
 *
 * NOT ROUTED. Nothing imports this, so it is never bundled and never crawled.
 * To use it, add a route temporarily:
 *
 *   { path: 'icon', loadComponent: () => import('./pages/icon/icon').then(m => m.Icon) }
 *
 * then `npm start` and screenshot http://localhost:4400/icon at 1024x1024:
 *
 *   chrome --headless=new --window-size=1024,1024 \
 *     --screenshot=icon.png http://localhost:4400/icon
 *
 * The render comes out as RGB with no alpha channel, which is what the App
 * Store requires — an icon carrying alpha is rejected even when it is opaque.
 * Remove the route again before deploying.
 */
@Component({
  selector: 'bp-icon',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<canvas #canvas width="1024" height="1024"></canvas>`,
  styles: `
    :host {
      position: fixed;
      inset: 0;
      z-index: 99999;
      display: grid;
      place-items: center;
      background: #000;
    }
    canvas {
      display: block;
      width: 1024px;
      height: 1024px;
    }
  `,
})
export class Icon {
  private readonly canvas = viewChild.required<ElementRef<HTMLCanvasElement>>('canvas');

  constructor() {
    afterNextRender(() => this.render());
  }

  private render(): void {
    const canvas = this.canvas().nativeElement;
    const renderer = new WebGLRenderer({ canvas, antialias: true, alpha: false });
    renderer.setPixelRatio(1);
    renderer.setSize(1024, 1024, false);
    renderer.outputColorSpace = SRGBColorSpace;
    renderer.toneMapping = ACESFilmicToneMapping;
    renderer.toneMappingExposure = 0.95;
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = PCFShadowMap;
    renderer.setClearColor(0x06070d, 1);

    const scene = new Scene();
    scene.fog = new Fog(0x06070d, 1.9, 4.4);

    // Same trick as the title sequence: a bright gradient standing in for a lit
    // ceiling, so the metal has something to reflect.
    const strip = document.createElement('canvas');
    strip.width = 8;
    strip.height = 32;
    const ctx = strip.getContext('2d')!;
    const sky = ctx.createLinearGradient(0, 0, 0, 32);
    sky.addColorStop(0, '#fff6e6');
    sky.addColorStop(0.35, '#c8c2b4');
    sky.addColorStop(0.52, '#5c6070');
    sky.addColorStop(1, '#0a0b10');
    ctx.fillStyle = sky;
    ctx.fillRect(0, 0, 8, 32);
    const equirect = new CanvasTexture(strip);
    equirect.mapping = EquirectangularReflectionMapping;
    equirect.colorSpace = SRGBColorSpace;
    const pmrem = new PMREMGenerator(renderer);
    scene.environment = pmrem.fromEquirectangular(equirect).texture;
    scene.environmentIntensity = 0.3;

    // ── the board ────────────────────────────────────────────────────────
    const { map, roughness } = boardTexture(2048);
    const surface = new Mesh(
      new BoxGeometry(8, 0.001, 8),
      new MeshPhysicalMaterial({
        map,
        color: new Color(0x6b6458),
        roughnessMap: roughness,
        roughness: 0.44,
        clearcoat: 0.55,
        clearcoatRoughness: 0.22,
      }),
    );
    surface.receiveShadow = true;
    scene.add(surface);

    const floor = new Mesh(
      new PlaneGeometry(60, 60),
      new MeshStandardMaterial({ color: 0x02030a, roughness: 0.95 }),
    );
    floor.rotation.x = -Math.PI / 2;
    floor.position.y = -0.14;
    scene.add(floor);

    // ── the pieces ───────────────────────────────────────────────────────
    const brass = new MeshPhysicalMaterial({
      color: new Color(0xecc078),
      metalness: 0.96,
      roughness: 0.16,
      clearcoat: 0.35,
    });
    const ivory = new MeshPhysicalMaterial({
      color: new Color(0xe6dfcd),
      roughness: 0.36,
      clearcoat: 0.55,
      clearcoatRoughness: 0.3,
    });
    const ebony = new MeshPhysicalMaterial({
      color: new Color(0x11131a),
      roughness: 0.3,
      metalness: 0.08,
      clearcoat: 0.75,
      clearcoatRoughness: 0.18,
    });

    const place = (
      kind: Parameters<typeof buildPieceGeometry>[0],
      material: MeshPhysicalMaterial,
      x: number,
      z: number,
      yaw = 0,
    ) => {
      const mesh = new Mesh(buildPieceGeometry(kind, 256), material);
      mesh.position.set(x, 0, z);
      mesh.rotation.y = yaw;
      mesh.castShadow = true;
      mesh.receiveShadow = true;
      scene.add(mesh);
      return mesh;
    };

    // The subject: one brass pawn, and the company it keeps falling away
    // behind it into the dark.
    place('pawn', brass, 0, 0, 0.3);
    // Company, kept far enough back and small enough that at forty pixels the
    // icon is one shape and not a crowd.
    place('king', ebony, 1.9, -3.1, 2.7);
    place('bishop', ivory, -2.1, -3.6, 1.1);
    place('rook', ebony, 1.1, -5.0, 0.2);

    // ── the light ────────────────────────────────────────────────────────
    const key = new SpotLight(0xfff0d2, 165, 14, Math.PI / 12, 0.3, 2);
    key.position.set(2.2, 2.9, 1.5);
    key.target.position.set(0, 0.25, 0);
    key.castShadow = true;
    key.shadow.mapSize.set(2048, 2048);
    key.shadow.bias = -0.0012;
    key.shadow.normalBias = 0.02;
    scene.add(key, key.target);

    const rim = new SpotLight(0x8fb4ea, 120, 22, Math.PI / 6, 0.7, 2);
    rim.position.set(-2.4, 1.3, -2.4);
    rim.target.position.set(0, 0.3, 0);
    scene.add(rim, rim.target);

    const practical = new PointLight(0xffc47a, 2.2, 2.2, 2);
    practical.position.set(-0.42, 0.24, 0.55);
    scene.add(practical);

    scene.add(new AmbientLight(0x141b2c, 0.35));

    // ── the shot ─────────────────────────────────────────────────────────
    // Low, close and slightly long, the way a product photograph is taken:
    // the pawn stands over the lens instead of being looked down upon.
    const camera = new PerspectiveCamera(23, 1, 0.05, 60);
    camera.position.set(0.4, 0.44, 1.82);
    camera.lookAt(0.025, 0.265, 0);

    renderer.render(scene, camera);
  }
}
