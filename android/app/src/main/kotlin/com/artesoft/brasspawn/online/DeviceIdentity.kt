package com.artesoft.brasspawn.online

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.SecureRandom
import java.security.Signature
import java.security.spec.ECGenParameterSpec

/**
 * Who this install is, to the online service.
 *
 * Android has no Game Center, so the account is a key: an ECDSA P-256 pair
 * made in the Android Keystore the first time online play is opened. The
 * private half never leaves the device (and, where there is one, the secure
 * hardware); the service knows the account by the public half. Signing in is
 * signing a fresh timestamp with it — nothing to type, nothing to remember,
 * and nothing about the person is sent.
 */
class DeviceIdentity(context: Context) {
    private val preferences = context.applicationContext.getSharedPreferences("online", Context.MODE_PRIVATE)

    /** A random name for this install, which sessions are bound to. Not an identifier of the device. */
    val device: String = preferences.getString("device", null) ?: run {
        val bytes = ByteArray(16).also { SecureRandom().nextBytes(it) }
        bytes.joinToString("") { "%02x".format(it) }.also { preferences.edit().putString("device", it).apply() }
    }

    class Proof(val publicKey: String, val timestampMs: Long, val signature: String)

    /** A proof good for one login: the service takes each only once, and only for five minutes. */
    fun proof(nowMs: Long = System.currentTimeMillis()): Proof {
        val entry = keyEntry()
        val message = "brasspawn/device-login/v1\n$device\n$nowMs".toByteArray(Charsets.UTF_8)
        val signature = Signature.getInstance("SHA256withECDSA").run {
            initSign(entry.privateKey)
            update(message)
            sign()
        }
        return Proof(
            publicKey = Base64.encodeToString(entry.certificate.publicKey.encoded, Base64.NO_WRAP),
            timestampMs = nowMs,
            signature = Base64.encodeToString(signature, Base64.NO_WRAP),
        )
    }

    /** Forget the key: the next login is a new account. For "delete my account". */
    fun reset() {
        KeyStore.getInstance(STORE).apply { load(null) }.deleteEntry(ALIAS)
    }

    private fun keyEntry(): KeyStore.PrivateKeyEntry {
        val store = KeyStore.getInstance(STORE).apply { load(null) }
        (store.getEntry(ALIAS, null) as? KeyStore.PrivateKeyEntry)?.let { return it }
        KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, STORE).apply {
            initialize(
                KeyGenParameterSpec.Builder(ALIAS, KeyProperties.PURPOSE_SIGN)
                    .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
                    .setDigests(KeyProperties.DIGEST_SHA256)
                    .build()
            )
            generateKeyPair()
        }
        return store.getEntry(ALIAS, null) as KeyStore.PrivateKeyEntry
    }

    private companion object {
        const val STORE = "AndroidKeyStore"
        const val ALIAS = "brasspawn.online.device"
    }
}
