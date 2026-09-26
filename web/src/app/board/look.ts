import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';

import { BoardSettings } from './board';
import { BoardStyle, Carving, CARVINGS, LightTone, PIECE_SETS, PieceSet, STYLES, TONES } from './config';

/**
 * How the reader's boards look — the app's Settings → Board, in a row: flat,
 * with its squares, pieces and light side, or in the round, with its set.
 * Every board on the page answers it at once, and the choice is kept in the
 * reader's browser.
 */
@Component({
  selector: 'bp-board-look',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="look mono">
      <div class="seg" role="group" aria-label="Board">
        <button type="button" [class.on]="config().dimension === '2d'" (click)="set({ dimension: '2d' })">2D</button>
        <button type="button" [class.on]="config().dimension === '3d'" (click)="set({ dimension: '3d' })">3D</button>
      </div>
      <!-- As Settings has it: the squares, the stains and the light side are
           the flat board's, and in the round the only choice is the set. -->
      @if (config().dimension === '3d') {
        <label>
          <span class="sr">Set</span>
          <select [value]="config().carving" (change)="set({ carving: $any($event.target).value })">
            @for (carving of carvings; track carving.id) {
              <option [value]="carving.id" [selected]="carving.id === config().carving">{{ carving.name }}</option>
            }
          </select>
        </label>
      } @else {
        <label>
          <span class="sr">Squares</span>
          <select [value]="config().style" (change)="set({ style: $any($event.target).value })">
            @for (style of styles; track style.id) {
              <option [value]="style.id" [selected]="style.id === config().style">{{ style.name }}</option>
            }
          </select>
        </label>
        <label>
          <span class="sr">Pieces</span>
          <select [value]="config().pieces" (change)="set({ pieces: $any($event.target).value })">
            @for (set of sets; track set.id) {
              <option [value]="set.id" [selected]="set.id === config().pieces">{{ set.name }}</option>
            }
          </select>
        </label>
        <label>
          <span class="sr">Light side</span>
          <select [value]="config().tone" (change)="set({ tone: $any($event.target).value })">
            @for (tone of tones; track tone.id) {
              <option [value]="tone.id" [selected]="tone.id === config().tone">{{ tone.name }}</option>
            }
          </select>
        </label>
      }
    </div>
  `,
  styles: `
    .look { display: flex; flex-wrap: wrap; gap: 0.5rem; align-items: center; font-size: var(--label); letter-spacing: 0.08em; }
    .seg { display: inline-flex; border: 1px solid var(--rule); border-radius: 999px; overflow: hidden; }
    .seg button, select {
      font: inherit; letter-spacing: inherit; color: var(--ivory-dim);
      background: transparent; border: 0; padding: 0.45rem 0.8rem; cursor: pointer;
    }
    .seg button.on { background: var(--brass); color: #120e06; }
    select {
      border: 1px solid var(--rule); border-radius: 999px; padding-right: 1.6rem;
      appearance: none; -webkit-appearance: none;
      background: linear-gradient(45deg, transparent 50%, var(--ivory-faint) 50%) calc(100% - 0.9rem) 55% / 5px 5px no-repeat,
        linear-gradient(135deg, var(--ivory-faint) 50%, transparent 50%) calc(100% - 0.6rem) 55% / 5px 5px no-repeat;
    }
    select option { color: #111; }
    .sr { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); }
  `,
})
export class BoardLook {
  private readonly settings = inject(BoardSettings);
  protected readonly config = computed(() => this.settings.config());

  protected readonly styles = (Object.keys(STYLES) as BoardStyle[]).map((id) => ({ id, name: STYLES[id].name }));
  protected readonly sets = (Object.keys(PIECE_SETS) as PieceSet[]).map((id) => ({ id, name: PIECE_SETS[id].name }));
  protected readonly tones = (Object.keys(TONES) as LightTone[]).map((id) => ({ id, name: TONES[id].name }));
  protected readonly carvings = (Object.keys(CARVINGS) as Carving[]).map((id) => ({ id, name: CARVINGS[id].name }));

  protected set(change: Parameters<BoardSettings['update']>[0]): void {
    this.settings.update(change);
  }
}
