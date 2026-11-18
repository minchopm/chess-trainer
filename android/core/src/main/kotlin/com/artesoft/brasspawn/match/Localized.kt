package com.artesoft.brasspawn.match

import com.artesoft.brasspawn.chess.PieceColor
import java.util.Locale

/**
 * Text the training layer produces for the player to read.
 *
 * Kept behind explicit keys rather than left as literals, because a sentence
 * this layer builds — "Black to play", "Mate in 3" — is shown on screen just
 * as much as anything in a view, and a phrase assembled from English fragments
 * cannot be translated at all: word order is not a detail other languages
 * agree with us about.
 */
object L {
    /**
     * Where the app plugs its string resources in: the text for a key, or
     * null when there is none. Nothing in this module knows about Android, so
     * the lookup comes from outside; with no resolver — which is what happens
     * in the tests — and for any string a translator has not reached yet, the
     * English source is what is shown.
     *
     * The strings keep the format specifiers the iOS catalog uses (`%@`,
     * `%lld`, `%1$@`), so one set of translations serves both apps.
     */
    @Volatile
    var resolver: ((key: String) -> String?)? = null

    /**
     * Looks the key up, falling back to the English source, and fills in the
     * arguments. With no arguments the text is handed back as it is, a "%" in
     * it included — the same as the Swift overload that takes none.
     */
    fun t(key: String, default: String, vararg args: Any?): String {
        val text = resolver?.invoke(key) ?: default
        return if (args.isEmpty()) text else format(text, args)
    }

    fun color(color: PieceColor): String =
        if (color == PieceColor.WHITE) t("color.white", "White") else t("color.black", "Black")

    /** A `String(format:)` specifier: `%@`, `%lld`, `%2$@`, `%.1f`, `%02d`, `%%`. */
    private val specifier =
        Regex("""%(?:(\d+)[$])?([-+ 0#]*)(\d+)?(?:\.(\d+))?(?:hh|h|ll|l|q|L|z|t|j)?([@dDiuUxXofFeEgGsScC%])""")

    /**
     * Substitutes the specifiers `String(format:)` understands. An argument
     * the text asks for and was not given leaves its specifier standing, so a
     * mistake in a translation is visible on screen rather than a crash.
     */
    private fun format(text: String, args: Array<out Any?>): String {
        var next = 0
        return specifier.replace(text) { match ->
            val (position, flags, width, precision, conversion) = match.destructured
            if (conversion == "%") return@replace "%"
            val index = if (position.isEmpty()) next++ else position.toInt() - 1
            if (index < 0 || index >= args.size) return@replace match.value
            render(args[index], flags, width, precision, conversion[0]) ?: match.value
        }
    }

    private fun render(argument: Any?, flags: String, width: String, precision: String, conversion: Char): String? {
        val layout = flags + width
        return try {
            when (conversion) {
                '@', 's', 'S' -> pad(argument?.toString() ?: "(null)", layout)
                'd', 'D', 'i', 'u', 'U' -> when (argument) {
                    is Number -> String.format(Locale.ROOT, "%${layout}d", argument.toLong())
                    else -> pad(argument.toString(), layout)
                }
                'x', 'X', 'o' -> when (argument) {
                    is Number -> String.format(Locale.ROOT, "%$layout$conversion", argument.toLong())
                    else -> pad(argument.toString(), layout)
                }
                'f', 'F', 'e', 'E', 'g', 'G' -> when (argument) {
                    is Number -> {
                        val places = if (precision.isEmpty()) "" else ".$precision"
                        val javaConversion = if (conversion == 'F') 'f' else conversion
                        String.format(Locale.ROOT, "%$layout$places$javaConversion", argument.toDouble())
                    }
                    else -> pad(argument.toString(), layout)
                }
                'c', 'C' -> when (argument) {
                    is Char -> argument.toString()
                    is Number -> String(Character.toChars(argument.toInt()))
                    else -> argument.toString()
                }
                else -> null
            }
        } catch (unformattable: IllegalArgumentException) {
            // A combination of flags Java's formatter will not take.
            null
        }
    }

    /** Applies a width to text: right-aligned unless the flags say "-". */
    private fun pad(text: String, layout: String): String {
        val width = layout.trimStart('-', '+', ' ', '0', '#').toIntOrNull() ?: return text
        return if ('-' in layout) text.padEnd(width) else text.padStart(width)
    }
}
