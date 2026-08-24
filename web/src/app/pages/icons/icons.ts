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
  CanvasTexture,
  Color,
  DirectionalLight,
  EquirectangularReflectionMapping,
  ExtrudeGeometry,
  Mesh,
  MeshPhysicalMaterial,
  OrthographicCamera,
  PMREMGenerator,
  SRGBColorSpace,
  Scene,
  WebGLRenderer,
} from 'three';

import { scratch } from '../../three/board';
import { GLYPHS } from '../../three/glyphs';

/**
 * The icon set, rendered — a render target, not a page.
 *
 * One orthographic camera and one directional light for every icon in the set,
 * laid out side by side in a single scene. That is the point of doing it this
 * way: consistency of stroke weight, optical size, bevel and highlight
 * direction is not something anyone has to maintain, because they are the same
 * objects in the same room photographed in the same exposure.
 *
 * The camera is straight on, deliberately. A tilt would skew every silhouette
 * away from the glyph it has to be recognised as; the depth comes from the
 * bevel catching the light, which is what still reads at twenty-four points
 * when a full three-dimensional object would have turned to mush.
 *
 * NOT ROUTED. To export, add a route temporarily:
 *
 *   { path: 'icons', loadComponent: () => import('./pages/icons/icons').then(m => m.Icons) }
 *
 *   chrome --headless=new --window-size=2560,1024 --default-background-color=00000000 \
 *     --screenshot=icons.png http://localhost:4400/icons
 */

const CELL = 30;
const NAMES = Object.keys(GLYPHS);

@Component({
  selector: 'bp-icons',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<canvas #canvas width="2560" height="1024"></canvas>`,
  styles: `
    :host {
      position: fixed;
      inset: 0;
      z-index: 99999;
      display: grid;
      place-items: center;
      background: transparent;
    }
    canvas {
      display: block;
      width: 2560px;
      height: 1024px;
    }
  `,
})
export class Icons {
  private readonly canvas = viewChild.required<ElementRef<HTMLCanvasElement>>('canvas');

  constructor() {
    afterNextRender(() => {
      document.documentElement.style.background = 'transparent';
      document.body.style.background = 'transparent';
      document.querySelectorAll('bp-site-header, bp-site-footer').forEach((el) => {
        (el as HTMLElement).style.display = 'none';
      });
      this.render();
    });
  }

  private render(): void {
    const canvas = this.canvas().nativeElement;
    const renderer = new WebGLRenderer({ canvas, antialias: true, alpha: true });
    renderer.setPixelRatio(1);
    renderer.setSize(2560, 1024, false);
    renderer.outputColorSpace = SRGBColorSpace;
    renderer.toneMapping = ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.0;
    renderer.setClearColor(0x000000, 0);

    const scene = new Scene();

    // Something for the metal to reflect — the same trick the title sequence
    // uses, so brass here and brass on the board are the same brass.
    const strip = scratch(8, 32);
    const ctx = strip.getContext('2d') as CanvasRenderingContext2D;
    const sky = ctx.createLinearGradient(0, 0, 0, 32);
    sky.addColorStop(0, '#fff6e6');
    sky.addColorStop(0.4, '#c8c2b4');
    sky.addColorStop(0.55, '#5c6070');
    sky.addColorStop(1, '#12141a');
    ctx.fillStyle = sky;
    ctx.fillRect(0, 0, 8, 32);
    const equirect = new CanvasTexture(strip as HTMLCanvasElement);
    equirect.mapping = EquirectangularReflectionMapping;
    equirect.colorSpace = SRGBColorSpace;
    const pmrem = new PMREMGenerator(renderer);
    scene.environment = pmrem.fromEquirectangular(equirect).texture;
    scene.environmentIntensity = 1.1;

    const ivory = new MeshPhysicalMaterial({
      color: new Color(0xe8e2d2),
      roughness: 0.36,
      metalness: 0.0,
      clearcoat: 0.5,
      clearcoatRoughness: 0.28,
    });
    const brass = new MeshPhysicalMaterial({
      color: new Color(0xd9a45c),
      metalness: 0.6,
      roughness: 0.3,
      clearcoat: 0.45,
      clearcoatRoughness: 0.2,
    });

    NAMES.forEach((name, column) => {
      const shapes = GLYPHS[name]();
      [ivory, brass].forEach((material, row) => {
        for (const shape of shapes) {
          // Shallow, with a bevel about the width of a stroke. Deep enough to
          // catch a light, not deep enough to become an illustration.
          const geometry = new ExtrudeGeometry(shape, {
            depth: 1.9,
            bevelEnabled: true,
            bevelThickness: 0.34,
            bevelSize: 0.34,
            bevelSegments: 4,
            curveSegments: 24,
          });
          const mesh = new Mesh(geometry, material);
          mesh.position.set((column - (NAMES.length - 1) / 2) * CELL, row === 0 ? 15 : -15, 0);
          scene.add(mesh);
        }
      });
    });

    // One lamp, upper right — the same corner the board's key light comes from,
    // so an icon and a piece are lit by the same room.
    const key = new DirectionalLight(0xfff2df, 3.1);
    key.position.set(6, 9, 8);
    scene.add(key);

    const fill = new DirectionalLight(0x8fb4ea, 0.9);
    fill.position.set(-7, -4, 5);
    scene.add(fill);

    scene.add(new AmbientLight(0xa8b2c4, 0.55));

    const halfWidth = (NAMES.length * CELL) / 2;
    const camera = new OrthographicCamera(-halfWidth, halfWidth, CELL, -CELL, 0.1, 200);
    camera.position.set(0, 0, 60);
    camera.lookAt(0, 0, 0);

    renderer.render(scene, camera);
  }
}
