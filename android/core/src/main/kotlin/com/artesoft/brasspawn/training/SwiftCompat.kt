@file:OptIn(ExperimentalSerializationApi::class)

package com.artesoft.brasspawn.training

import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZonedDateTime
import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.truncate
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerializationException
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonDecoder
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonEncoder
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.JsonUnquotedLiteral
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.intOrNull

// What the Swift code gets from Foundation without asking, and this module has
// to say out loud: how a `Double` rounds, how an `Int` reads, what a calendar
// day is, and — most of this file — what `JSONEncoder` writes. Nothing here has
// a counterpart among the Swift sources; everything else in the package does.

// MARK: - Numbers and text

/**
 * Rounds to the nearest whole number, a half going away from zero: what
 * Swift's `rounded()` does, and neither of the things Kotlin's `round` and
 * `roundToInt` do with a half.
 */
internal fun swiftRounded(value: Double): Int {
    val whole = truncate(value)
    // The difference is exact, so a value a hair under a half stays under it.
    return (if (abs(value - whole) >= 0.5) whole + (if (value < 0) -1.0 else 1.0) else whole).toInt()
}

/**
 * Swift's `Int(_ text:)`: an optional sign and ASCII digits, nothing else.
 * `toIntOrNull` alone would also read the digits of other scripts.
 */
internal fun swiftInt(text: CharSequence): Int? {
    if (text.isEmpty()) return null
    for ((index, character) in text.withIndex()) {
        val isSign = index == 0 && (character == '+' || character == '-')
        if (!isSign && (character < '0' || character > '9')) return null
    }
    return text.toString().toIntOrNull()
}

/** Swift's `split(separator:)`: the pieces between separators, empty ones left out. */
internal fun swiftSplit(text: String, separator: Char): List<String> =
    text.split(separator).filter { it.isNotEmpty() }

// MARK: - Calendar days

/** Seconds between the Unix epoch and the first moment of 2001, UTC — Foundation's reference date. */
internal const val referenceDateOffset = 978_307_200.0

/** The calendar day an instant falls on, where `zone` is. */
internal fun localDate(seconds: Double, zone: ZoneId): LocalDate =
    Instant.ofEpochSecond(floor(seconds).toLong()).atZone(zone).toLocalDate()

/** `Calendar.startOfDay(for:)`: the first moment of the day an instant falls on, as an instant. */
internal fun startOfDay(seconds: Double, zone: ZoneId): Double =
    localDate(seconds, zone).atStartOfDay(zone).toEpochSecond().toDouble()

internal fun ZonedDateTime.toSeconds(): Double = toEpochSecond().toDouble()

// MARK: - JSON, as Swift's JSONEncoder writes it

/**
 * The format everything this package keeps is read and written with.
 *
 * It is the shape Swift's `JSONEncoder` gives the types these are ported from,
 * with nothing configured — which is how the iPhone app writes its progress
 * file — so a file from one app is a file the other can open:
 *
 *  - an optional that is nil is left out, not written as `null`;
 *  - a `Date` is a number, seconds since the first moment of 2001
 *    ([SwiftDateSerializer]);
 *  - an enum is its raw value;
 *  - a dictionary keyed by an enum is an array, key then value then key
 *    ([SwiftDictionarySerializer]); one keyed by a string is an object;
 *  - a `Set` is an array;
 *  - a `Double` with nothing after the point is written without one
 *    ([SwiftDoubleSerializer]).
 *
 * Read tolerantly: a key this build does not know is passed over, and a value
 * it does not know — a board style a later build added — falls back to the
 * default where there is one, rather than costing somebody their whole file.
 */
internal val swiftJson = Json {
    ignoreUnknownKeys = true
    encodeDefaults = true
    explicitNulls = false
    coerceInputValues = true
}

/** A number as Swift's encoder writes a `Double`: whole values without a fraction, and never an exponent. */
private fun swiftNumber(value: Double): JsonElement {
    if (!value.isFinite()) throw SerializationException("$value cannot be written as JSON")
    if (value == floor(value) && abs(value) < 1e15) return JsonPrimitive(value.toLong())
    return JsonUnquotedLiteral(BigDecimal(value.toString()).toPlainString())
}

/** A `Double`, written the way Swift writes one: `300`, not `300.0`. */
internal object SwiftDoubleSerializer : KSerializer<Double> {
    override val descriptor: SerialDescriptor =
        PrimitiveSerialDescriptor("com.artesoft.brasspawn.training.SwiftDouble", PrimitiveKind.DOUBLE)

    override fun serialize(encoder: Encoder, value: Double) {
        if (encoder is JsonEncoder) encoder.encodeJsonElement(swiftNumber(value)) else encoder.encodeDouble(value)
    }

    override fun deserialize(decoder: Decoder): Double = decoder.decodeDouble()
}

/**
 * An instant. In memory it is seconds since the Unix epoch, as everywhere in
 * this module; on disk it is what Swift's `JSONEncoder` makes of a `Date` when
 * nobody has told it otherwise — seconds since the first moment of 2001.
 */
internal object SwiftDateSerializer : KSerializer<Double> {
    override val descriptor: SerialDescriptor =
        PrimitiveSerialDescriptor("com.artesoft.brasspawn.training.SwiftDate", PrimitiveKind.DOUBLE)

    override fun serialize(encoder: Encoder, value: Double) {
        val sinceReference = value - referenceDateOffset
        if (encoder is JsonEncoder) encoder.encodeJsonElement(swiftNumber(sinceReference)) else encoder.encodeDouble(sinceReference)
    }

    override fun deserialize(decoder: Decoder): Double = decoder.decodeDouble() + referenceDateOffset
}

/**
 * A dictionary whose keys are an enum, as Swift writes one: not an object but
 * a flat array, `["tactics", 3, "rush", 1]`. Swift keeps an object for
 * dictionaries keyed by `String` or `Int` and nothing else, so this is what
 * `[TrainingActivity: Int]` and `[TrainingMode: Int]` look like on disk.
 *
 * Read back from either shape. A key this build has never heard of is passed
 * over with its value; an array with a key and no value is not a dictionary,
 * and is refused as Swift refuses it.
 */
internal open class SwiftDictionarySerializer<K : Any>(
    private val keys: KSerializer<K>,
    name: String,
) : KSerializer<Map<K, Int>> {
    private val element = JsonElement.serializer()

    override val descriptor: SerialDescriptor = SerialDescriptor(name, element.descriptor)

    override fun serialize(encoder: Encoder, value: Map<K, Int>) {
        val json = (encoder as? JsonEncoder)
            ?: throw SerializationException("${descriptor.serialName} is only written as JSON")
        json.encodeJsonElement(buildJsonArray {
            for ((key, count) in value) {
                add(json.json.encodeToJsonElement(keys, key))
                add(JsonPrimitive(count))
            }
        })
    }

    override fun deserialize(decoder: Decoder): Map<K, Int> {
        val json = (decoder as? JsonDecoder)
            ?: throw SerializationException("${descriptor.serialName} is only read from JSON")
        val result = LinkedHashMap<K, Int>()
        fun put(key: JsonElement, value: JsonElement) {
            val count = (value as? JsonPrimitive)?.takeIf { !it.isString }?.intOrNull
                ?: throw SerializationException("${descriptor.serialName}: $value is not a count")
            val decoded = try {
                json.json.decodeFromJsonElement(keys, key)
            } catch (_: SerializationException) {
                return
            }
            result[decoded] = count
        }
        when (val tree = json.decodeJsonElement()) {
            is JsonArray -> {
                if (tree.size % 2 != 0) {
                    throw SerializationException("${descriptor.serialName}: expected key-value pairs, found an odd-length array")
                }
                for (index in 0 until tree.size step 2) put(tree[index], tree[index + 1])
            }
            is JsonObject -> for ((key, value) in tree) put(JsonPrimitive(key), value)
            is JsonNull -> Unit
            else -> throw SerializationException("${descriptor.serialName}: expected an array of key-value pairs")
        }
        return result
    }
}
