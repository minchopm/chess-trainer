package com.artesoft.brasspawn.online

import android.content.Context
import com.google.android.gms.net.CronetProviderInstaller
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import org.chromium.net.CronetEngine
import org.chromium.net.CronetException
import org.chromium.net.UploadDataProviders
import org.chromium.net.UrlRequest
import org.chromium.net.UrlResponseInfo
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.nio.ByteBuffer
import java.util.concurrent.Executors
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class HttpReply(val status: Int, val body: String)

/** How a request reaches the online service. */
interface HttpTransport {
    suspend fun send(method: String, url: String, headers: Map<String, String>, body: String?, timeoutMs: Int): HttpReply
}

/**
 * The service is the Cloud Rush game server, which listens on QUIC only: its
 * HTTPS origin is HTTP/3 and nothing else. Cronet is the platform's HTTP/3
 * stack (the one Chrome uses), so that is what talks to it; the plain
 * connection below is for the development server, which is clear-text HTTP on
 * the machine running the emulator.
 */
object Transports {
    suspend fun forBaseUrl(context: Context, baseUrl: String): HttpTransport {
        val url = URL(baseUrl)
        if (url.protocol != "https") return UrlConnectionTransport
        return runCatching {
            CronetProviderInstaller.installProvider(context.applicationContext).await()
            val port = if (url.port > 0) url.port else 443
            val engine = CronetEngine.Builder(context.applicationContext)
                .enableQuic(true)
                .enableHttp2(true)
                // No Alt-Svc to learn it from: the origin is QUIC from the first packet.
                .addQuicHint(url.host, port, port)
                .build()
            CronetTransport(engine) as HttpTransport
        }.getOrElse { UrlConnectionTransport }
    }
}

object UrlConnectionTransport : HttpTransport {
    override suspend fun send(method: String, url: String, headers: Map<String, String>, body: String?, timeoutMs: Int): HttpReply =
        withContext(Dispatchers.IO) {
            val connection = URL(url).openConnection() as HttpURLConnection
            try {
                connection.requestMethod = method
                connection.connectTimeout = 10_000
                connection.readTimeout = timeoutMs
                headers.forEach(connection::setRequestProperty)
                if (body != null) {
                    connection.doOutput = true
                    connection.setRequestProperty("Content-Type", "application/json")
                    connection.outputStream.use { it.write(body.toByteArray(Charsets.UTF_8)) }
                }
                val status = connection.responseCode
                val stream = if (status in 200..299) connection.inputStream else connection.errorStream
                HttpReply(status, stream?.bufferedReader()?.use { it.readText() }.orEmpty())
            } finally {
                connection.disconnect()
            }
        }
}

class CronetTransport(private val engine: CronetEngine) : HttpTransport {
    private val executor = Executors.newCachedThreadPool()

    override suspend fun send(method: String, url: String, headers: Map<String, String>, body: String?, timeoutMs: Int): HttpReply =
        suspendCancellableCoroutine { continuation ->
            val received = ByteArrayOutputStream()
            val callback = object : UrlRequest.Callback() {
                override fun onRedirectReceived(request: UrlRequest, info: UrlResponseInfo, newLocationUrl: String) = request.cancel()

                override fun onResponseStarted(request: UrlRequest, info: UrlResponseInfo) =
                    request.read(ByteBuffer.allocateDirect(16 * 1024))

                override fun onReadCompleted(request: UrlRequest, info: UrlResponseInfo, buffer: ByteBuffer) {
                    buffer.flip()
                    val bytes = ByteArray(buffer.remaining()).also { buffer.get(it) }
                    received.write(bytes)
                    if (received.size() > MAX_REPLY) {
                        request.cancel()
                        return
                    }
                    buffer.clear()
                    request.read(buffer)
                }

                override fun onSucceeded(request: UrlRequest, info: UrlResponseInfo) {
                    if (continuation.isActive) continuation.resume(HttpReply(info.httpStatusCode, received.toString("UTF-8")))
                }

                override fun onFailed(request: UrlRequest, info: UrlResponseInfo?, error: CronetException) {
                    if (continuation.isActive) continuation.resumeWithException(IOException(error.message, error))
                }

                override fun onCanceled(request: UrlRequest, info: UrlResponseInfo?) {
                    if (continuation.isActive) continuation.resumeWithException(IOException("cancelled"))
                }
            }
            val builder = engine.newUrlRequestBuilder(url, callback, executor).setHttpMethod(method)
            headers.forEach(builder::addHeader)
            if (body != null) {
                builder.addHeader("Content-Type", "application/json")
                builder.setUploadDataProvider(UploadDataProviders.create(body.toByteArray(Charsets.UTF_8)), executor)
            }
            val request = builder.build()
            continuation.invokeOnCancellation { request.cancel() }
            request.start()
        }

    private companion object {
        const val MAX_REPLY = 1 shl 20
    }
}
