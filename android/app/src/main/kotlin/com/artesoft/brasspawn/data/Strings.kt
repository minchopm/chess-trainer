package com.artesoft.brasspawn.data

import android.content.Context
import android.os.LocaleList
import com.artesoft.brasspawn.match.L
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonPrimitive
import java.util.Locale

/**
 * What the app says, in the language of the device.
 *
 * The tables are the iOS string catalog, key for key (tools/strings.py), so a
 * sentence reads the same on both platforms and a translation is made once.
 * Anything a table lacks falls back to English — which is also what is passed
 * at every call site, as on iOS.
 */
object Strings {
    @Volatile private var table: Map<String, String> = emptyMap()
    @Volatile private var english: Map<String, String> = emptyMap()
    @Volatile var language: String = "en"
        private set

    val isRightToLeft: Boolean
        get() = language.substringBefore('-') in setOf("ar", "he", "iw", "ur", "fa")

    private fun readAssetTable(context: Context, name: String): Map<String, String> = runCatching {
        val text = context.assets.open("l10n/$name.json").bufferedReader().use { it.readText() }
        Json.decodeFromString<JsonObject>(text).mapValues { it.value.jsonPrimitive.content }
    }.getOrDefault(emptyMap())

    private fun availableTables(context: Context): List<String> = runCatching {
        Json.decodeFromString<List<String>>(context.assets.open("l10n/index.json").bufferedReader().use { it.readText() })
    }.getOrDefault(listOf("en"))

    fun load(context: Context, locales: LocaleList = context.resources.configuration.locales) {
        val available = availableTables(context)
        english = readAssetTable(context, "en")
        val chosen = (0 until locales.size()).firstNotNullOfOrNull { match(locales[it], available) } ?: "en"
        language = chosen
        val base = chosen.substringBefore('-')
        table = when {
            chosen == "en" -> english
            base != chosen && base in available -> readAssetTable(context, base) + readAssetTable(context, chosen)
            else -> readAssetTable(context, chosen)
        }
        L.resolver = Strings::lookup
    }

    /**
     * Loads a named catalog table directly for debug storefront captures,
     * falling back from a regional tag to its base language and then English.
     */
    fun loadExplicit(context: Context, tag: String) {
        val normalized = tag.trim().replace('_', '-')
        val available = availableTables(context)
        english = readAssetTable(context, "en")
        val rawBase = normalized.substringBefore('-')
        val base = when (rawBase) {
            "iw" -> "he"
            "in" -> "id"
            "nn" -> "nb"
            else -> rawBase
        }
        val candidates = buildList {
            add(normalized)
            if (rawBase != base && '-' in normalized) add("$base-${normalized.substringAfter('-')}")
            if (base == "zh") {
                val traditional = "Hant" in normalized || normalized.endsWith("-TW") || normalized.endsWith("-HK") || normalized.endsWith("-MO")
                add(if (traditional) "zh-Hant" else "zh-Hans")
            }
            add(base)
            if (base == "nb") add("no")
            if (base == "no") add("nb")
        }
        val chosen = candidates.firstOrNull { it in available } ?: "en"
        language = normalized.ifEmpty { chosen }
        table = when {
            chosen == "en" -> english
            base != chosen && base in available -> readAssetTable(context, base) + readAssetTable(context, chosen)
            else -> readAssetTable(context, chosen)
        }
        runCatching { Locale.setDefault(Locale.forLanguageTag(language)) }
        L.resolver = Strings::lookup
    }

    /** The table for a locale: the exact tag, then script, then the language alone. */
    private fun match(locale: Locale, available: List<String>): String? {
        val language = when (locale.language) {
            "iw" -> "he"
            "in" -> "id"
            "nb", "nn" -> "nb"
            else -> locale.language
        }
        val candidates = buildList {
            if (language == "zh") {
                val traditional = locale.script == "Hant" || locale.country in setOf("TW", "HK", "MO")
                add(if (traditional) "zh-Hant" else "zh-Hans")
            }
            if (locale.country.isNotEmpty()) add("$language-${locale.country}")
            add(language)
            if (language == "nb") add("no")
        }
        return candidates.firstOrNull { it in available }
    }

    /** The string for a key, or `null` when no table has it. */
    fun lookup(key: String): String? = table[key] ?: english[key]

    fun t(key: String, default: String, vararg args: Any?): String =
        format(lookup(key) ?: default, args)

    /**
     * Swift's format specifiers, substituted here: `%@`, `%lld`, `%d`, `%.1f`
     * and their positional forms (`%1$@`).
     */
    fun format(pattern: String, args: Array<out Any?>): String {
        if (args.isEmpty() || '%' !in pattern) return pattern.replace("%%", "%")
        var next = 0
        return SPECIFIER.replace(pattern) { found ->
            val (position, precision, kind) = found.destructured
            if (kind == "%") return@replace "%"
            val index = if (position.isNotEmpty()) position.toInt() - 1 else next++
            val value = args.getOrNull(index) ?: return@replace ""
            when (kind) {
                "f" -> if (value is Number) {
                    String.format(Locale.getDefault(), "%${precision}f", value.toDouble())
                } else value.toString()
                else -> value.toString()
            }
        }
    }

    private val SPECIFIER = Regex("""%(?:(\d+)\$)?(\.\d+)?(@|lld|ld|d|li|i|u|f|%)""")
}

/** Shorthand used across the UI, as `L.t` is on iOS. */
fun t(key: String, default: String, vararg args: Any?): String = Strings.t(key, default, *args)
