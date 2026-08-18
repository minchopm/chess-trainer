// Interactive chessboard: HTML pieces over a CSS grid, with an SVG overlay for
// arrows and circles. Knows nothing about chess rules — the caller supplies the
// legal destinations and decides what a move means.

const FILES = 'abcdefgh';
const GLYPHS = {
  wk: '♔', wq: '♕', wr: '♖', wb: '♗', wn: '♘', wp: '♙',
  bk: '♚', bq: '♛', br: '♜', bb: '♝', bn: '♞', bp: '♟',
};

export function squareToCoords(square) {
  return [FILES.indexOf(square[0]), 8 - Number(square[1])]; // [file 0-7, rank-from-top 0-7]
}

export function coordsToSquare(file, rank) {
  return `${FILES[file]}${8 - rank}`;
}

/** Parse the piece-placement field of a FEN into a Map of square -> "wp" style codes. */
export function fenToPieces(fen) {
  const pieces = new Map();
  const rows = fen.split(' ')[0].split('/');
  rows.forEach((row, rankIdx) => {
    let fileIdx = 0;
    for (const ch of row) {
      if (/\d/.test(ch)) {
        fileIdx += Number(ch);
        continue;
      }
      const color = ch === ch.toUpperCase() ? 'w' : 'b';
      pieces.set(coordsToSquare(fileIdx, rankIdx), color + ch.toLowerCase());
      fileIdx += 1;
    }
  });
  return pieces;
}

export class Board {
  #root;
  #squaresEl;
  #piecesEl;
  #hintsEl;
  #overlayEl;
  #promoEl;

  #pieces = new Map(); // square -> { code, el }
  #dests = new Map(); // from-square -> [to-square]
  #selected = null;
  #drag = null;
  #pendingPromotion = null;

  orientation = 'white';
  interactive = true;
  onMove = null; // (from, to, promotion) => boolean | Promise<boolean>

  constructor(root, options = {}) {
    this.#root = root;
    this.orientation = options.orientation ?? 'white';
    this.onMove = options.onMove ?? null;
    if (options.interactive === false) this.interactive = false;

    root.classList.add('board');
    root.innerHTML = `
      <div class="board-squares"></div>
      <svg class="board-overlay" viewBox="0 0 8 8" preserveAspectRatio="none">
        <defs>
          <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5"
                  markerWidth="4" markerHeight="4" orient="auto-start-reverse">
            <path d="M 0 0 L 10 5 L 0 10 z" fill="context-stroke"></path>
          </marker>
        </defs>
        <g class="overlay-shapes"></g>
      </svg>
      <div class="board-hints"></div>
      <div class="board-pieces"></div>
      <div class="board-promo" hidden></div>`;

    this.#squaresEl = root.querySelector('.board-squares');
    this.#overlayEl = root.querySelector('.overlay-shapes');
    this.#hintsEl = root.querySelector('.board-hints');
    this.#piecesEl = root.querySelector('.board-pieces');
    this.#promoEl = root.querySelector('.board-promo');

    this.#buildSquares();
    this.#bindPointer();
    this.#applyOrientation();
  }

  #buildSquares() {
    const frag = document.createDocumentFragment();
    for (let rank = 0; rank < 8; rank += 1) {
      for (let file = 0; file < 8; file += 1) {
        const sq = document.createElement('div');
        sq.className = `sq ${(file + rank) % 2 === 0 ? 'light' : 'dark'}`;
        sq.dataset.square = coordsToSquare(file, rank);
        if (file === 0) sq.dataset.rankLabel = String(8 - rank);
        if (rank === 7) sq.dataset.fileLabel = FILES[file];
        frag.append(sq);
      }
    }
    this.#squaresEl.append(frag);
  }

  #applyOrientation() {
    this.#root.dataset.orientation = this.orientation;
  }

  /** Pixel-space position of a square's top-left corner, as a 0-100 percentage pair. */
  #squarePercent(square) {
    let [file, rank] = squareToCoords(square);
    if (this.orientation === 'black') {
      file = 7 - file;
      rank = 7 - rank;
    }
    return [file * 100, rank * 100];
  }

  #squareFromPoint(clientX, clientY) {
    const rect = this.#root.getBoundingClientRect();
    const x = (clientX - rect.left) / rect.width;
    const y = (clientY - rect.top) / rect.height;
    if (x < 0 || x >= 1 || y < 0 || y >= 1) return null;
    let file = Math.floor(x * 8);
    let rank = Math.floor(y * 8);
    if (this.orientation === 'black') {
      file = 7 - file;
      rank = 7 - rank;
    }
    return coordsToSquare(file, rank);
  }

  #placePiece(el, square) {
    const [x, y] = this.#squarePercent(square);
    el.style.transform = `translate(${x}%, ${y}%)`;
  }

  #createPiece(code, square) {
    const el = document.createElement('div');
    el.className = `piece ${code}`;
    el.textContent = GLYPHS[code];
    el.dataset.code = code;
    this.#placePiece(el, square);
    this.#piecesEl.append(el);
    return el;
  }

  /**
   * Render a position. Pieces that merely moved are reused so CSS transitions
   * animate them instead of popping.
   */
  setPosition(fen, { lastMove = null, check = null, animate = true } = {}) {
    const target = fenToPieces(fen);
    this.#piecesEl.classList.toggle('no-animation', !animate);

    // Reuse elements: first keep every piece already standing on a correct square.
    const leftovers = new Map(); // code -> [el]
    const next = new Map();
    for (const [square, entry] of this.#pieces) {
      if (target.get(square) === entry.code) {
        next.set(square, entry);
      } else {
        if (!leftovers.has(entry.code)) leftovers.set(entry.code, []);
        leftovers.get(entry.code).push(entry.el);
      }
    }

    for (const [square, code] of target) {
      if (next.has(square)) continue;
      const pool = leftovers.get(code);
      if (pool?.length) {
        const el = pool.shift();
        this.#placePiece(el, square);
        next.set(square, { code, el });
      } else {
        next.set(square, { code, el: this.#createPiece(code, square) });
      }
    }

    for (const pool of leftovers.values()) for (const el of pool) el.remove();

    this.#pieces = next;
    this.#selected = null;
    this.#renderHints();
    this.#renderSquareStates(lastMove, check);

    if (!animate) {
      // Force a reflow so the class removal below doesn't animate this frame's change.
      void this.#piecesEl.offsetWidth;
      this.#piecesEl.classList.remove('no-animation');
    }
  }

  #renderSquareStates(lastMove, check) {
    for (const el of this.#squaresEl.children) {
      el.classList.toggle('last-move', Boolean(lastMove) && lastMove.includes(el.dataset.square));
      el.classList.toggle('in-check', el.dataset.square === check);
    }
  }

  /** dests: Map<fromSquare, string[]>. Pass an empty map to freeze the board. */
  setMovable(dests) {
    this.#dests = dests ?? new Map();
    this.#selected = null;
    this.#renderHints();
  }

  #renderHints() {
    this.#hintsEl.replaceChildren();
    for (const el of this.#squaresEl.children) {
      el.classList.toggle('selected', el.dataset.square === this.#selected);
    }
    if (!this.#selected) return;

    for (const to of this.#dests.get(this.#selected) ?? []) {
      const hint = document.createElement('div');
      hint.className = this.#pieces.has(to) ? 'hint capture' : 'hint';
      const [x, y] = this.#squarePercent(to);
      hint.style.transform = `translate(${x}%, ${y}%)`;
      this.#hintsEl.append(hint);
    }
  }

  #canMoveFrom(square) {
    return this.interactive && (this.#dests.get(square)?.length ?? 0) > 0;
  }

  #bindPointer() {
    this.#root.addEventListener('pointerdown', (event) => {
      if (event.button !== 0 || this.#pendingPromotion) return;
      const square = this.#squareFromPoint(event.clientX, event.clientY);
      if (!square) return;

      // Second click of a click-move.
      if (this.#selected && this.#selected !== square) {
        if ((this.#dests.get(this.#selected) ?? []).includes(square)) {
          const from = this.#selected;
          this.#selected = null;
          this.#renderHints();
          this.#attemptMove(from, square);
          return;
        }
      }

      if (!this.#canMoveFrom(square)) {
        this.#selected = null;
        this.#renderHints();
        return;
      }

      this.#selected = square;
      this.#renderHints();

      const entry = this.#pieces.get(square);
      if (!entry) return;
      this.#root.setPointerCapture(event.pointerId);
      const rect = this.#root.getBoundingClientRect();
      this.#drag = { from: square, el: entry.el, rect, pointerId: event.pointerId, moved: false };
      entry.el.classList.add('dragging');
      this.#followPointer(event.clientX, event.clientY);
      event.preventDefault();
    });

    this.#root.addEventListener('pointermove', (event) => {
      if (!this.#drag || event.pointerId !== this.#drag.pointerId) return;
      this.#drag.moved = true;
      this.#followPointer(event.clientX, event.clientY);
      const over = this.#squareFromPoint(event.clientX, event.clientY);
      for (const el of this.#squaresEl.children) {
        el.classList.toggle('hover', el.dataset.square === over);
      }
    });

    const endDrag = (event) => {
      if (!this.#drag || event.pointerId !== this.#drag.pointerId) return;
      const { from, el, moved } = this.#drag;
      this.#drag = null;
      el.classList.remove('dragging');
      el.style.left = '';
      el.style.top = '';
      for (const child of this.#squaresEl.children) child.classList.remove('hover');

      const to = this.#squareFromPoint(event.clientX, event.clientY);
      this.#placePiece(el, from);

      if (!moved || !to || to === from) return; // treat as a plain selection click
      this.#selected = null;
      this.#renderHints();
      if ((this.#dests.get(from) ?? []).includes(to)) this.#attemptMove(from, to);
    };

    this.#root.addEventListener('pointerup', endDrag);
    this.#root.addEventListener('pointercancel', endDrag);
    this.#root.addEventListener('contextmenu', (event) => event.preventDefault());
  }

  #followPointer(clientX, clientY) {
    const { el, rect } = this.#drag;
    const size = rect.width / 8;
    el.style.left = `${clientX - rect.left - size / 2}px`;
    el.style.top = `${clientY - rect.top - size / 2}px`;
    el.style.transform = 'none';
  }

  async #attemptMove(from, to) {
    // Guard against a second attempt arriving before the first has been
    // applied: some input paths deliver both pointer and mouse events, and a
    // duplicated move would be played against an already-updated position.
    if (this.#moving) return;
    this.#moving = true;
    try {
      await this.#doMove(from, to);
    } finally {
      this.#moving = false;
    }
  }

  #moving = false;

  async #doMove(from, to) {
    const entry = this.#pieces.get(from);
    const isPromotion =
      entry?.code[1] === 'p' && (to[1] === '8' || to[1] === '1');

    const promotion = isPromotion ? await this.#askPromotion(to, entry.code[0]) : undefined;
    if (isPromotion && !promotion) return; // cancelled

    await this.onMove?.(from, to, promotion);
  }

  #askPromotion(square, color) {
    return new Promise((resolve) => {
      const [x] = this.#squarePercent(square);
      const fromTop = this.#squarePercent(square)[1] === 0;
      this.#promoEl.innerHTML = '';
      this.#promoEl.style.left = `${x}%`;
      this.#promoEl.style.top = fromTop ? '0' : 'auto';
      this.#promoEl.style.bottom = fromTop ? 'auto' : '0';
      this.#promoEl.dataset.direction = fromTop ? 'down' : 'up';

      for (const kind of ['q', 'r', 'b', 'n']) {
        const button = document.createElement('button');
        button.className = `piece ${color}${kind}`;
        button.textContent = GLYPHS[color + kind];
        button.addEventListener('click', () => {
          this.#promoEl.hidden = true;
          this.#pendingPromotion = null;
          resolve(kind);
        });
        this.#promoEl.append(button);
      }

      const cancel = (event) => {
        if (this.#promoEl.contains(event.target)) return;
        this.#promoEl.hidden = true;
        this.#pendingPromotion = null;
        this.#root.removeEventListener('pointerdown', cancel, true);
        resolve(null);
      };

      this.#pendingPromotion = true;
      this.#promoEl.hidden = false;
      setTimeout(() => this.#root.addEventListener('pointerdown', cancel, true), 0);
    });
  }

  flip() {
    this.orientation = this.orientation === 'white' ? 'black' : 'white';
    this.#applyOrientation();
    for (const [square, entry] of this.#pieces) this.#placePiece(entry.el, square);
    this.#renderHints();
    this.#redrawShapes();
  }

  setOrientation(orientation) {
    if (orientation === this.orientation) return;
    this.flip();
  }

  // --- overlay shapes -------------------------------------------------------

  #shapes = [];

  #centerOf(square) {
    const [x, y] = this.#squarePercent(square);
    return [x / 100 + 0.5, y / 100 + 0.5];
  }

  #redrawShapes() {
    this.#overlayEl.replaceChildren();
    for (const shape of this.#shapes) {
      if (shape.type === 'arrow') {
        const [x1, y1] = this.#centerOf(shape.from);
        const [x2, y2] = this.#centerOf(shape.to);
        // Stop the arrow short of the square centre so the head sits nicely.
        const dx = x2 - x1;
        const dy = y2 - y1;
        const len = Math.hypot(dx, dy) || 1;
        const trim = 0.32;
        const line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
        line.setAttribute('x1', x1 + (dx / len) * 0.18);
        line.setAttribute('y1', y1 + (dy / len) * 0.18);
        line.setAttribute('x2', x2 - (dx / len) * trim);
        line.setAttribute('y2', y2 - (dy / len) * trim);
        line.setAttribute('stroke', shape.color);
        line.setAttribute('stroke-width', '0.13');
        line.setAttribute('stroke-linecap', 'round');
        line.setAttribute('marker-end', 'url(#arrowhead)');
        line.setAttribute('opacity', shape.opacity ?? 0.85);
        this.#overlayEl.append(line);
      } else if (shape.type === 'circle') {
        const [cx, cy] = this.#centerOf(shape.square);
        const circle = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
        circle.setAttribute('cx', cx);
        circle.setAttribute('cy', cy);
        circle.setAttribute('r', 0.42);
        circle.setAttribute('fill', 'none');
        circle.setAttribute('stroke', shape.color);
        circle.setAttribute('stroke-width', '0.07');
        circle.setAttribute('opacity', shape.opacity ?? 0.9);
        this.#overlayEl.append(circle);
      }
    }
  }

  drawArrow(from, to, color = '#4f9d5b', opacity) {
    this.#shapes.push({ type: 'arrow', from, to, color, opacity });
    this.#redrawShapes();
  }

  drawCircle(square, color = '#4f9d5b', opacity) {
    this.#shapes.push({ type: 'circle', square, color, opacity });
    this.#redrawShapes();
  }

  clearShapes() {
    this.#shapes = [];
    this.#redrawShapes();
  }
}
