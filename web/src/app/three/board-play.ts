import { BufferGeometry, Group, Material, Mesh, Vector3 } from 'three';

import { Ply } from './games';
import { PieceKind } from './pieces';

/**
 * The board, playing.
 *
 * Owns thirty-two meshes and moves them. It knows nothing about chess beyond
 * what a `Ply` tells it — which piece goes where, what it takes, and whether a
 * rook comes with it — because the legality was settled by chess.js long
 * before the browser saw the move.
 *
 * Nothing is ever created or destroyed after construction: a taken piece
 * shrinks away and its mesh goes back in the pool, and resetting for the next
 * game puts all thirty-two back where they started. A title sequence that runs
 * for as long as somebody leaves the tab open cannot afford to allocate per
 * move.
 */

/** a1 is the far corner for White; one square is one unit. */
export function squareToPosition(square: string, into = new Vector3()): Vector3 {
  return into.set(square.charCodeAt(0) - 97 - 3.5, 0, 3.5 - (Number(square[1]) - 1));
}

export interface PieceMaterials {
  readonly ivory: Material;
  readonly ebony: Material;
  /** Warmed by the key light — worn by whichever piece is moving. */
  readonly ivoryLit: Material;
  readonly ebonyLit: Material;
  /** The bands and finials, on both sides of the board. */
  readonly brass: Material;
  readonly brassLit: Material;
}

interface Piece {
  readonly mesh: Mesh;
  readonly white: boolean;
  readonly homeSquare: string;
  readonly homeKind: PieceKind;
  kind: PieceKind;
}

interface Travel {
  readonly piece: Piece;
  readonly from: Vector3;
  readonly to: Vector3;
  readonly span: number;
  readonly lift: number;
  readonly lit: boolean;
  readonly promotion?: PieceKind;
  t: number;
}

interface Taken {
  readonly piece: Piece;
  readonly span: number;
  t: number;
}

const BACK_RANK: readonly PieceKind[] = [
  'rook',
  'knight',
  'bishop',
  'queen',
  'king',
  'bishop',
  'knight',
  'rook',
];

const FILES = 'abcdefgh';

/** The standard array, as thirty-two [square, kind, white] triples. */
function startingPosition(): { square: string; kind: PieceKind; white: boolean }[] {
  const out: { square: string; kind: PieceKind; white: boolean }[] = [];
  for (let file = 0; file < 8; file++) {
    out.push({ square: `${FILES[file]}1`, kind: BACK_RANK[file], white: true });
    out.push({ square: `${FILES[file]}2`, kind: 'pawn', white: true });
    out.push({ square: `${FILES[file]}7`, kind: 'pawn', white: false });
    out.push({ square: `${FILES[file]}8`, kind: BACK_RANK[file], white: false });
  }
  return out;
}

const easeInOut = (t: number): number =>
  t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;

const easeIn = (t: number): number => t * t * t;

export class PlayingBoard {
  readonly group = new Group();

  /** Where the action is, for a light to follow. Eased, not snapped. */
  readonly focus = new Vector3(0, 0.4, 0);

  private readonly pool: Piece[] = [];
  private readonly squares = new Map<string, Piece>();
  private readonly travels: Travel[] = [];
  private readonly taken: Taken[] = [];
  private readonly focusTarget = new Vector3(0, 0.4, 0);
  private readonly scratch = new Vector3();
  private readonly pairs: Material[][];

  constructor(
    private readonly geometries: Record<PieceKind, BufferGeometry>,
    private readonly materials: PieceMaterials,
  ) {
    const { ivory, ivoryLit, ebony, ebonyLit, brass, brassLit } = materials;
    this.pairs = [
      [ivory, brass],
      [ivoryLit, brassLit],
      [ebony, brass],
      [ebonyLit, brassLit],
    ];

    for (const placement of startingPosition()) {
      const mesh = new Mesh(geometries[placement.kind], this.material(placement.white, false));
      mesh.castShadow = true;
      mesh.receiveShadow = true;
      // Knights face the other side; the rest are turned to match so a set
      // looks placed rather than dropped.
      mesh.rotation.y = placement.white ? Math.PI : 0;
      this.group.add(mesh);

      this.pool.push({
        mesh,
        white: placement.white,
        homeSquare: placement.square,
        homeKind: placement.kind,
        kind: placement.kind,
      });
    }

    this.reset();
  }

  /** True when every piece has finished moving. */
  get idle(): boolean {
    return this.travels.length === 0;
  }

  /** Puts all thirty-two back on their squares, ready for the next game. */
  reset(): void {
    this.travels.length = 0;
    this.taken.length = 0;
    this.squares.clear();

    for (const piece of this.pool) {
      piece.kind = piece.homeKind;
      piece.mesh.geometry = this.geometries[piece.homeKind];
      piece.mesh.material = this.material(piece.white, false);
      piece.mesh.scale.setScalar(1);
      piece.mesh.visible = true;
      piece.mesh.rotation.set(0, piece.white ? Math.PI : 0, 0);
      squareToPosition(piece.homeSquare, piece.mesh.position);
      this.squares.set(piece.homeSquare, piece);
    }

    this.focusTarget.set(0, 0.4, 0);
  }

  /**
   * Starts one half-move. Silently does nothing if the board and the move list
   * have somehow disagreed — a title sequence that throws is worse than a
   * title sequence that skips a move.
   */
  play(ply: Ply): void {
    const mover = this.squares.get(ply.from);
    if (!mover) return;

    if (ply.capture) {
      const victim = this.squares.get(ply.capture);
      if (victim) {
        this.squares.delete(ply.capture);
        this.taken.push({ piece: victim, span: 0.42, t: 0 });
      }
    }

    this.squares.delete(ply.from);
    this.squares.set(ply.to, mover);
    this.start(mover, ply.to, ply.kind === 'knight', true, ply.promotion);

    if (ply.rookFrom && ply.rookTo) {
      const rook = this.squares.get(ply.rookFrom);
      if (rook) {
        this.squares.delete(ply.rookFrom);
        this.squares.set(ply.rookTo, rook);
        this.start(rook, ply.rookTo, false, false);
      }
    }

    squareToPosition(ply.to, this.focusTarget).setY(0.45);
  }

  update(delta: number): void {
    for (let i = this.travels.length - 1; i >= 0; i--) {
      const travel = this.travels[i];
      travel.t += delta;
      const k = Math.min(1, travel.t / travel.span);
      const e = easeInOut(k);

      travel.piece.mesh.position.lerpVectors(travel.from, travel.to, e);
      // A knight is the only piece that goes over things, so it is the only
      // one that leaves the board by more than a lift-and-place.
      travel.piece.mesh.position.y = Math.sin(Math.PI * k) * travel.lift;

      if (k >= 1) {
        travel.piece.mesh.position.copy(travel.to);
        if (travel.lit) {
          travel.piece.mesh.material = this.material(travel.piece.white, false);
        }
        if (travel.promotion) {
          travel.piece.kind = travel.promotion;
          travel.piece.mesh.geometry = this.geometries[travel.promotion];
        }
        this.travels.splice(i, 1);
      }
    }

    for (let i = this.taken.length - 1; i >= 0; i--) {
      const take = this.taken[i];
      take.t += delta;
      const k = Math.min(1, take.t / take.span);

      // Lifted off the board and away, rather than sunk through it: a piece
      // disappearing downwards reads as a bug from a low camera.
      take.piece.mesh.scale.setScalar(1 - easeIn(k));
      take.piece.mesh.position.y = k * 0.35;
      take.piece.mesh.rotation.y += delta * 2.4;

      if (k >= 1) {
        take.piece.mesh.visible = false;
        take.piece.mesh.scale.setScalar(1);
        this.taken.splice(i, 1);
      }
    }

    // The focus lags the move, so the light arrives with the piece rather than
    // ahead of it.
    this.focus.lerp(this.focusTarget, Math.min(1, delta * 2.6));
  }

  private start(piece: Piece, to: string, hop: boolean, lit: boolean, promotion?: PieceKind): void {
    if (lit) piece.mesh.material = this.material(piece.white, true);

    this.travels.push({
      piece,
      from: piece.mesh.position.clone(),
      to: squareToPosition(to, this.scratch.clone()),
      span: hop ? 0.62 : 0.5,
      lift: hop ? 0.85 : 0.16,
      lit,
      promotion,
      t: 0,
    });
  }

  /**
   * The four pairs a piece can wear, made once.
   *
   * Body first and brass second, which is the order `buildPieceGeometry` puts
   * the two groups in. A piece that is moving warms both: the brass catches the
   * key light along with the wood it is wrapped around, and lighting only one
   * of them makes the bands look like they belong to a different piece.
   */
  private material(white: boolean, lit: boolean): Material[] {
    return this.pairs[(white ? 0 : 2) + (lit ? 1 : 0)];
  }
}
