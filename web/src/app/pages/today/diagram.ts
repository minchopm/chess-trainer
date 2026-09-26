import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';

interface Placed {
  readonly code: string;
  readonly x: number;
  readonly y: number;
}

/**
 * A position, drawn: the app's walnut squares and the app's own pieces.
 *
 * SVG in the template rather than a picture, so the prerendered page carries
 * the board itself — a crawler reads the pieces' alternative text, the board
 * is sharp at any size, and there is no image to regenerate when a story is
 * corrected. The same drawing as scripts/feed/diagram.mjs; keep them in step.
 */
@Component({
  selector: 'bp-diagram',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <svg viewBox="0 0 8 8" role="img" [attr.aria-label]="label()">
      @for (square of squares; track $index) {
        <rect [attr.x]="square.x" [attr.y]="square.y" width="1" height="1" [attr.fill]="square.fill" />
      }
      @for (mark of marks(); track $index) {
        <rect [attr.x]="mark.x" [attr.y]="mark.y" width="1" height="1" class="mark" />
      }
      @for (piece of pieces(); track $index) {
        <image [attr.href]="'pieces/' + piece.code + '.png'" [attr.x]="piece.x" [attr.y]="piece.y" width="1" height="1" />
      }
    </svg>
  `,
  styles: `
    :host { display: block; }
    svg { display: block; width: 100%; height: auto; border-radius: 3px; }
    .mark { fill: rgba(255, 214, 92, 0.5); }
  `,
})
export class Diagram {
  readonly fen = input.required<string>();
  readonly last = input<{ from: string; to: string } | null>(null);
  /** Black at the bottom — for a story told from Black's side. */
  readonly flip = input(false);
  readonly label = input('Chess position');

  protected readonly squares = Array.from({ length: 64 }, (_, i) => {
    const x = i % 8;
    const y = Math.floor(i / 8);
    return { x, y, fill: (x + y) % 2 === 0 ? '#CB9B66' : '#6C432C' };
  });

  private place(square: string): { x: number; y: number } {
    const file = square.charCodeAt(0) - 97;
    const rank = Number(square[1]) - 1;
    return this.flip() ? { x: 7 - file, y: rank } : { x: file, y: 7 - rank };
  }

  protected readonly marks = computed(() => {
    const last = this.last();
    return last ? [this.place(last.from), this.place(last.to)] : [];
  });

  protected readonly pieces = computed(() => {
    const placed: Placed[] = [];
    this.fen()
      .split(' ')[0]
      .split('/')
      .forEach((row, r) => {
        let file = 0;
        for (const ch of row) {
          if (/\d/.test(ch)) {
            file += Number(ch);
            continue;
          }
          const code = (ch === ch.toUpperCase() ? 'w' : 'b') + ch.toUpperCase();
          placed.push({ code, ...this.place(String.fromCharCode(97 + file) + (8 - r)) });
          file++;
        }
      });
    return placed;
  });
}
