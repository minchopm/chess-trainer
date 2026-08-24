import { PieceKind } from './pieces';

/**
 * The games the title sequence plays out.
 *
 * Three of the most famous attacking games ever recorded, chosen because each
 * one ends in mate and none of them is a grind: a title sequence has about a
 * minute of a viewer's attention and needs every move to be doing something.
 *
 * The move lists are not typed out by hand. They were expanded from PGN by
 * chess.js — every move validated, captures resolved to the square the taken
 * piece actually stood on (which for en passant is not the destination), and
 * castling split into the two pieces that move. If a move in the source PGN
 * had been wrong the expansion would have thrown rather than shipped.
 */

/** One half-move, with everything the board needs to animate it. */
export interface Ply {
  readonly from: string;
  readonly to: string;
  readonly kind: PieceKind;
  readonly white: boolean;
  /** Square the captured piece stands on — not always `to`. */
  readonly capture?: string;
  readonly promotion?: PieceKind;
  /** Castling moves a rook as well. */
  readonly rookFrom?: string;
  readonly rookTo?: string;
  readonly san: string;
}

export interface Game {
  readonly id: string;
  readonly white: string;
  readonly black: string;
  readonly event: string;
  readonly year: number;
  readonly result: string;
  readonly note: string;
  readonly plies: readonly Ply[];
}

export const GAMES: readonly Game[] = [
  {
    id: 'opera',
    white: 'Paul Morphy',
    black: 'Duke of Brunswick & Count Isouard',
    event: 'Paris Opera',
    year: 1858,
    result: '1–0',
    note: 'Seventeen moves, every one of them developing something, and a mate delivered by the last piece to arrive.',
    plies: [
      { from: 'e2', to: 'e4', kind: 'pawn', white: true, san: 'e4' },
      { from: 'e7', to: 'e5', kind: 'pawn', white: false, san: 'e5' },
      { from: 'g1', to: 'f3', kind: 'knight', white: true, san: 'Nf3' },
      { from: 'd7', to: 'd6', kind: 'pawn', white: false, san: 'd6' },
      { from: 'd2', to: 'd4', kind: 'pawn', white: true, san: 'd4' },
      { from: 'c8', to: 'g4', kind: 'bishop', white: false, san: 'Bg4' },
      { from: 'd4', to: 'e5', kind: 'pawn', white: true, capture: 'e5', san: 'dxe5' },
      { from: 'g4', to: 'f3', kind: 'bishop', white: false, capture: 'f3', san: 'Bxf3' },
      { from: 'd1', to: 'f3', kind: 'queen', white: true, capture: 'f3', san: 'Qxf3' },
      { from: 'd6', to: 'e5', kind: 'pawn', white: false, capture: 'e5', san: 'dxe5' },
      { from: 'f1', to: 'c4', kind: 'bishop', white: true, san: 'Bc4' },
      { from: 'g8', to: 'f6', kind: 'knight', white: false, san: 'Nf6' },
      { from: 'f3', to: 'b3', kind: 'queen', white: true, san: 'Qb3' },
      { from: 'd8', to: 'e7', kind: 'queen', white: false, san: 'Qe7' },
      { from: 'b1', to: 'c3', kind: 'knight', white: true, san: 'Nc3' },
      { from: 'c7', to: 'c6', kind: 'pawn', white: false, san: 'c6' },
      { from: 'c1', to: 'g5', kind: 'bishop', white: true, san: 'Bg5' },
      { from: 'b7', to: 'b5', kind: 'pawn', white: false, san: 'b5' },
      { from: 'c3', to: 'b5', kind: 'knight', white: true, capture: 'b5', san: 'Nxb5' },
      { from: 'c6', to: 'b5', kind: 'pawn', white: false, capture: 'b5', san: 'cxb5' },
      { from: 'c4', to: 'b5', kind: 'bishop', white: true, capture: 'b5', san: 'Bxb5+' },
      { from: 'b8', to: 'd7', kind: 'knight', white: false, san: 'Nbd7' },
      {
        from: 'e1',
        to: 'c1',
        kind: 'king',
        white: true,
        rookFrom: 'a1',
        rookTo: 'd1',
        san: 'O-O-O',
      },
      { from: 'a8', to: 'd8', kind: 'rook', white: false, san: 'Rd8' },
      { from: 'd1', to: 'd7', kind: 'rook', white: true, capture: 'd7', san: 'Rxd7' },
      { from: 'd8', to: 'd7', kind: 'rook', white: false, capture: 'd7', san: 'Rxd7' },
      { from: 'h1', to: 'd1', kind: 'rook', white: true, san: 'Rd1' },
      { from: 'e7', to: 'e6', kind: 'queen', white: false, san: 'Qe6' },
      { from: 'b5', to: 'd7', kind: 'bishop', white: true, capture: 'd7', san: 'Bxd7+' },
      { from: 'f6', to: 'd7', kind: 'knight', white: false, capture: 'd7', san: 'Nxd7' },
      { from: 'b3', to: 'b8', kind: 'queen', white: true, san: 'Qb8+' },
      { from: 'd7', to: 'b8', kind: 'knight', white: false, capture: 'b8', san: 'Nxb8' },
      { from: 'd1', to: 'd8', kind: 'rook', white: true, san: 'Rd8#' },
    ],
  },
  {
    id: 'evergreen',
    white: 'Adolf Anderssen',
    black: 'Jean Dufresne',
    event: 'Berlin',
    year: 1852,
    result: '1–0',
    note: 'The Evergreen. A queen given away on move nineteen for a mate that takes five more.',
    plies: [
      { from: 'e2', to: 'e4', kind: 'pawn', white: true, san: 'e4' },
      { from: 'e7', to: 'e5', kind: 'pawn', white: false, san: 'e5' },
      { from: 'g1', to: 'f3', kind: 'knight', white: true, san: 'Nf3' },
      { from: 'b8', to: 'c6', kind: 'knight', white: false, san: 'Nc6' },
      { from: 'f1', to: 'c4', kind: 'bishop', white: true, san: 'Bc4' },
      { from: 'f8', to: 'c5', kind: 'bishop', white: false, san: 'Bc5' },
      { from: 'b2', to: 'b4', kind: 'pawn', white: true, san: 'b4' },
      { from: 'c5', to: 'b4', kind: 'bishop', white: false, capture: 'b4', san: 'Bxb4' },
      { from: 'c2', to: 'c3', kind: 'pawn', white: true, san: 'c3' },
      { from: 'b4', to: 'a5', kind: 'bishop', white: false, san: 'Ba5' },
      { from: 'd2', to: 'd4', kind: 'pawn', white: true, san: 'd4' },
      { from: 'e5', to: 'd4', kind: 'pawn', white: false, capture: 'd4', san: 'exd4' },
      { from: 'e1', to: 'g1', kind: 'king', white: true, rookFrom: 'h1', rookTo: 'f1', san: 'O-O' },
      { from: 'd4', to: 'd3', kind: 'pawn', white: false, san: 'd3' },
      { from: 'd1', to: 'b3', kind: 'queen', white: true, san: 'Qb3' },
      { from: 'd8', to: 'f6', kind: 'queen', white: false, san: 'Qf6' },
      { from: 'e4', to: 'e5', kind: 'pawn', white: true, san: 'e5' },
      { from: 'f6', to: 'g6', kind: 'queen', white: false, san: 'Qg6' },
      { from: 'f1', to: 'e1', kind: 'rook', white: true, san: 'Re1' },
      { from: 'g8', to: 'e7', kind: 'knight', white: false, san: 'Nge7' },
      { from: 'c1', to: 'a3', kind: 'bishop', white: true, san: 'Ba3' },
      { from: 'b7', to: 'b5', kind: 'pawn', white: false, san: 'b5' },
      { from: 'b3', to: 'b5', kind: 'queen', white: true, capture: 'b5', san: 'Qxb5' },
      { from: 'a8', to: 'b8', kind: 'rook', white: false, san: 'Rb8' },
      { from: 'b5', to: 'a4', kind: 'queen', white: true, san: 'Qa4' },
      { from: 'a5', to: 'b6', kind: 'bishop', white: false, san: 'Bb6' },
      { from: 'b1', to: 'd2', kind: 'knight', white: true, san: 'Nbd2' },
      { from: 'c8', to: 'b7', kind: 'bishop', white: false, san: 'Bb7' },
      { from: 'd2', to: 'e4', kind: 'knight', white: true, san: 'Ne4' },
      { from: 'g6', to: 'f5', kind: 'queen', white: false, san: 'Qf5' },
      { from: 'c4', to: 'd3', kind: 'bishop', white: true, capture: 'd3', san: 'Bxd3' },
      { from: 'f5', to: 'h5', kind: 'queen', white: false, san: 'Qh5' },
      { from: 'e4', to: 'f6', kind: 'knight', white: true, san: 'Nf6+' },
      { from: 'g7', to: 'f6', kind: 'pawn', white: false, capture: 'f6', san: 'gxf6' },
      { from: 'e5', to: 'f6', kind: 'pawn', white: true, capture: 'f6', san: 'exf6' },
      { from: 'h8', to: 'g8', kind: 'rook', white: false, san: 'Rg8' },
      { from: 'a1', to: 'd1', kind: 'rook', white: true, san: 'Rad1' },
      { from: 'h5', to: 'f3', kind: 'queen', white: false, capture: 'f3', san: 'Qxf3' },
      { from: 'e1', to: 'e7', kind: 'rook', white: true, capture: 'e7', san: 'Rxe7+' },
      { from: 'c6', to: 'e7', kind: 'knight', white: false, capture: 'e7', san: 'Nxe7' },
      { from: 'a4', to: 'd7', kind: 'queen', white: true, capture: 'd7', san: 'Qxd7+' },
      { from: 'e8', to: 'd7', kind: 'king', white: false, capture: 'd7', san: 'Kxd7' },
      { from: 'd3', to: 'f5', kind: 'bishop', white: true, san: 'Bf5+' },
      { from: 'd7', to: 'e8', kind: 'king', white: false, san: 'Ke8' },
      { from: 'f5', to: 'd7', kind: 'bishop', white: true, san: 'Bd7+' },
      { from: 'e8', to: 'f8', kind: 'king', white: false, san: 'Kf8' },
      { from: 'a3', to: 'e7', kind: 'bishop', white: true, capture: 'e7', san: 'Bxe7#' },
    ],
  },
  {
    id: 'immortal',
    white: 'Adolf Anderssen',
    black: 'Lionel Kieseritzky',
    event: 'London',
    year: 1851,
    result: '1–0',
    note: 'The Immortal. Both rooks and the queen given away, and mate with the three pieces left.',
    plies: [
      { from: 'e2', to: 'e4', kind: 'pawn', white: true, san: 'e4' },
      { from: 'e7', to: 'e5', kind: 'pawn', white: false, san: 'e5' },
      { from: 'f2', to: 'f4', kind: 'pawn', white: true, san: 'f4' },
      { from: 'e5', to: 'f4', kind: 'pawn', white: false, capture: 'f4', san: 'exf4' },
      { from: 'f1', to: 'c4', kind: 'bishop', white: true, san: 'Bc4' },
      { from: 'd8', to: 'h4', kind: 'queen', white: false, san: 'Qh4+' },
      { from: 'e1', to: 'f1', kind: 'king', white: true, san: 'Kf1' },
      { from: 'b7', to: 'b5', kind: 'pawn', white: false, san: 'b5' },
      { from: 'c4', to: 'b5', kind: 'bishop', white: true, capture: 'b5', san: 'Bxb5' },
      { from: 'g8', to: 'f6', kind: 'knight', white: false, san: 'Nf6' },
      { from: 'g1', to: 'f3', kind: 'knight', white: true, san: 'Nf3' },
      { from: 'h4', to: 'h6', kind: 'queen', white: false, san: 'Qh6' },
      { from: 'd2', to: 'd3', kind: 'pawn', white: true, san: 'd3' },
      { from: 'f6', to: 'h5', kind: 'knight', white: false, san: 'Nh5' },
      { from: 'f3', to: 'h4', kind: 'knight', white: true, san: 'Nh4' },
      { from: 'h6', to: 'g5', kind: 'queen', white: false, san: 'Qg5' },
      { from: 'h4', to: 'f5', kind: 'knight', white: true, san: 'Nf5' },
      { from: 'c7', to: 'c6', kind: 'pawn', white: false, san: 'c6' },
      { from: 'g2', to: 'g4', kind: 'pawn', white: true, san: 'g4' },
      { from: 'h5', to: 'f6', kind: 'knight', white: false, san: 'Nf6' },
      { from: 'h1', to: 'g1', kind: 'rook', white: true, san: 'Rg1' },
      { from: 'c6', to: 'b5', kind: 'pawn', white: false, capture: 'b5', san: 'cxb5' },
      { from: 'h2', to: 'h4', kind: 'pawn', white: true, san: 'h4' },
      { from: 'g5', to: 'g6', kind: 'queen', white: false, san: 'Qg6' },
      { from: 'h4', to: 'h5', kind: 'pawn', white: true, san: 'h5' },
      { from: 'g6', to: 'g5', kind: 'queen', white: false, san: 'Qg5' },
      { from: 'd1', to: 'f3', kind: 'queen', white: true, san: 'Qf3' },
      { from: 'f6', to: 'g8', kind: 'knight', white: false, san: 'Ng8' },
      { from: 'c1', to: 'f4', kind: 'bishop', white: true, capture: 'f4', san: 'Bxf4' },
      { from: 'g5', to: 'f6', kind: 'queen', white: false, san: 'Qf6' },
      { from: 'b1', to: 'c3', kind: 'knight', white: true, san: 'Nc3' },
      { from: 'f8', to: 'c5', kind: 'bishop', white: false, san: 'Bc5' },
      { from: 'c3', to: 'd5', kind: 'knight', white: true, san: 'Nd5' },
      { from: 'f6', to: 'b2', kind: 'queen', white: false, capture: 'b2', san: 'Qxb2' },
      { from: 'f4', to: 'd6', kind: 'bishop', white: true, san: 'Bd6' },
      { from: 'c5', to: 'g1', kind: 'bishop', white: false, capture: 'g1', san: 'Bxg1' },
      { from: 'e4', to: 'e5', kind: 'pawn', white: true, san: 'e5' },
      { from: 'b2', to: 'a1', kind: 'queen', white: false, capture: 'a1', san: 'Qxa1+' },
      { from: 'f1', to: 'e2', kind: 'king', white: true, san: 'Ke2' },
      { from: 'b8', to: 'a6', kind: 'knight', white: false, san: 'Na6' },
      { from: 'f5', to: 'g7', kind: 'knight', white: true, capture: 'g7', san: 'Nxg7+' },
      { from: 'e8', to: 'd8', kind: 'king', white: false, san: 'Kd8' },
      { from: 'f3', to: 'f6', kind: 'queen', white: true, san: 'Qf6+' },
      { from: 'g8', to: 'f6', kind: 'knight', white: false, capture: 'f6', san: 'Nxf6' },
      { from: 'd6', to: 'e7', kind: 'bishop', white: true, san: 'Be7#' },
    ],
  },
];
