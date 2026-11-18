package com.artesoft.brasspawn.chess

/** A move, plus the kind of move it is — which is what applying it needs to know. */
data class Move(
    val from: Square,
    val to: Square,
    val promotion: PieceKind? = null,
    val kind: Kind = Kind.QUIET,
) {
    enum class Kind {
        QUIET, CAPTURE, DOUBLE_PAWN_PUSH, EN_PASSANT, KINGSIDE_CASTLE, QUEENSIDE_CASTLE
    }

    val isCapture: Boolean get() = kind == Kind.CAPTURE || kind == Kind.EN_PASSANT
    val isCastle: Boolean get() = kind == Kind.KINGSIDE_CASTLE || kind == Kind.QUEENSIDE_CASTLE

    /** Long algebraic notation, the form UCI speaks: "e2e4", "e7e8q". */
    val uci: String
        get() {
            val text = StringBuilder(5).append(from.name).append(to.name)
            if (promotion != null) text.append(promotion.letter)
            return text.toString()
        }

    override fun toString(): String = uci

    /** Compares only the parts notation carries, ignoring the internal kind. */
    fun matchesNotation(of: Move): Boolean =
        from == of.from && to == of.to && promotion == of.promotion

    companion object {
        fun fromUci(uci: CharSequence): Move? {
            if (uci.length != 4 && uci.length != 5) return null
            val from = Square.parse(uci.subSequence(0, 2)) ?: return null
            val to = Square.parse(uci.subSequence(2, 4)) ?: return null
            var promotion: PieceKind? = null
            if (uci.length == 5) {
                promotion = PieceKind.fromLetter(uci[4]) ?: return null
            }
            // The kind is unknown from notation alone; Position resolves it when the
            // move is matched against the legal list.
            return Move(from, to, promotion)
        }
    }
}
