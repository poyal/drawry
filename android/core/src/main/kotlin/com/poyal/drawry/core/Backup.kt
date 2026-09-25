package com.poyal.drawry.core

import java.io.*
import java.nio.ByteBuffer
import java.security.MessageDigest
import java.util.Base64
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString

@Serializable
data class BackupHeader(
    val version: Int = 2,
    val iterations: Int = 210_000,
    val salt: String,
    val passwordWrap: String,
    val recoveryWrap: String,
)

@Serializable data class BackupFile(val name: String, val length: Long, val sha256: String)

@Serializable data class BackupManifest(val snapshot: Snapshot, val files: List<BackupFile>)

object Backup {
    const val ITERATIONS = 210_000

    private fun b64(bytes: ByteArray) = Base64.getEncoder().encodeToString(bytes)

    private fun decode(text: String) = Base64.getDecoder().decode(text)

    fun passwordKey(password: String, salt: ByteArray): ByteArray {
        // Explicit UTF-8 avoids provider-dependent PBE character conversion.
        require(password.isNotEmpty())
        val mac =
            Mac.getInstance("HmacSHA256").apply {
                init(SecretKeySpec(password.toByteArray(Charsets.UTF_8), "HmacSHA256"))
            }
        var u = mac.doFinal(salt + ChunkCipher.uint32(1))
        val result = u.copyOf()
        repeat(ITERATIONS - 1) {
            u = mac.doFinal(u)
            for (i in result.indices) result[i] = (result[i].toInt() xor u[i].toInt()).toByte()
        }
        return result
    }

    private fun wrap(key: ByteArray, wrapping: ByteArray, label: String): String {
        val nonce = ChunkCipher.random(12)
        return b64(nonce + ChunkCipher.seal(key, wrapping, nonce, label.toByteArray()))
    }

    private fun unwrap(text: String, key: ByteArray, label: String): ByteArray {
        val box = decode(text)
        require(box.size == 60)
        return ChunkCipher.open(
            box.copyOfRange(12, box.size),
            key,
            box.copyOfRange(0, 12),
            label.toByteArray(),
        )
    }

    fun digest(bytes: ByteArray): String =
        MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") { "%02x".format(it) }

    fun digest(file: File): String {
        val hash = MessageDigest.getInstance("SHA-256")
        file.inputStream().buffered().use { input ->
            val bytes = ByteArray(1 shl 20)
            while (true) {
                val n = input.read(bytes)
                if (n < 0) break
                hash.update(bytes, 0, n)
            }
        }
        return hash.digest().joinToString("") { "%02x".format(it) }
    }

    fun create(
        snapshot: Snapshot,
        mediaDirectory: File,
        destination: File,
        password: String,
        recoveryKey: ByteArray,
    ) {
        require(password.codePointCount(0, password.length) >= 8 && recoveryKey.size == 32)
        snapshot.validate()
        val salt = ChunkCipher.random(16)
        val dataKey = ChunkCipher.random(32)
        val header =
            wireJson
                .encodeToString(
                    BackupHeader(
                        salt = b64(salt),
                        passwordWrap =
                            wrap(dataKey, passwordKey(password, salt), "drawry-password-v2"),
                        recoveryWrap = wrap(dataKey, recoveryKey, "drawry-recovery-v2"),
                    )
                )
                .toByteArray(Charsets.UTF_8)
        val files =
            snapshot.diaries
                .flatMap { it.media }
                .flatMap { it.files }
                .sorted()
                .map { name ->
                    val file = File(mediaDirectory, name)
                    require(file.isFile)
                    BackupFile(name, file.length(), digest(file))
                }
        val manifest =
            wireJson.encodeToString(BackupManifest(snapshot, files)).toByteArray(Charsets.UTF_8)
        require(manifest.size <= 32 * 1024 * 1024)
        val payload = File(destination.path + ".payload")
        try {
            // Open one media stream at a time, so diary count cannot exhaust descriptors.
            val reader =
                object : InputStream() {
                    var current: InputStream =
                        ByteArrayInputStream(ChunkCipher.uint32(manifest.size) + manifest)
                    var index = 0

                    override fun read(): Int {
                        val b = ByteArray(1)
                        return if (read(b, 0, 1) < 0) -1 else b[0].toInt() and 255
                    }

                    override fun read(b: ByteArray, off: Int, len: Int): Int {
                        if (len == 0) return 0
                        while (true) {
                            val n = current.read(b, off, len)
                            if (n >= 0) return n
                            current.close()
                            if (index == files.size) return -1
                            current =
                                File(mediaDirectory, files[index++].name).inputStream().buffered()
                        }
                    }

                    override fun close() {
                        current.close()
                    }
                }
            reader.use {
                ChunkCipher.encrypt(
                    it,
                    4L + manifest.size + files.sumOf { it.length },
                    payload,
                    dataKey,
                    digest(header),
                )
            }
            destination.outputStream().buffered().use { out ->
                out.write("DRBK2".toByteArray())
                out.write(ChunkCipher.uint32(header.size))
                out.write(header)
                payload.inputStream().use { it.copyTo(out) }
            }
        } catch (e: Exception) {
            destination.delete()
            throw e
        } finally {
            payload.delete()
            dataKey.fill(0)
        }
    }

    fun restore(
        source: File,
        staging: File,
        password: String? = null,
        recoveryKey: ByteArray? = null,
    ): Snapshot {
        require(!staging.exists() && staging.mkdirs())
        var success = false
        try {
            val payload = File(staging, "payload.tmp")
            val (headerBytes, key) =
                source.inputStream().buffered().use { input ->
                    require(input.readExactly(5).contentEquals("DRBK2".toByteArray())) {
                        "지원하지 않는 백업입니다."
                    }
                    val n = ByteBuffer.wrap(input.readExactly(4)).int
                    require(n in 1..65536)
                    val bytes = input.readExactly(n)
                    val header =
                        wireJson.decodeFromString<BackupHeader>(bytes.toString(Charsets.UTF_8))
                    val salt = decode(header.salt)
                    require(
                        header.version == 2 && header.iterations == ITERATIONS && salt.size == 16
                    )
                    val dataKey =
                        if (!password.isNullOrEmpty())
                            unwrap(
                                header.passwordWrap,
                                passwordKey(password, salt),
                                "drawry-password-v2",
                            )
                        else {
                            require(recoveryKey?.size == 32)
                            unwrap(header.recoveryWrap, recoveryKey!!, "drawry-recovery-v2")
                        }
                    payload.outputStream().buffered().use { input.copyTo(it) }
                    bytes to dataKey
                }
            val receiver = PayloadReceiver(staging)
            val snapshot =
                try {
                    ChunkCipher.decrypt(payload, key, digest(headerBytes), receiver::accept)
                    receiver.finish()
                } finally {
                    receiver.close()
                    key.fill(0)
                }
            payload.delete()
            snapshot.diaries
                .flatMap { it.media }
                .forEach { media ->
                    media.files.forEach { name ->
                        ChunkCipher.decrypt(File(staging, name), decode(media.key), name) {}
                    }
                }
            success = true
            return snapshot
        } finally {
            if (!success) staging.deleteRecursively()
        }
    }
}

private class PayloadReceiver(val directory: File) : Closeable {
    var buffer = ByteArray(0)
    var manifestLength: Int? = null
    var manifest: BackupManifest? = null
    var index = 0
    var written = 0L
    var output: OutputStream? = null

    fun accept(data: ByteArray) {
        buffer += data
        if (manifestLength == null && buffer.size >= 4) {
            manifestLength =
                ByteBuffer.wrap(buffer, 0, 4).int.also { require(it in 1..32 * 1024 * 1024) }
            buffer = buffer.copyOfRange(4, buffer.size)
        }
        val n = manifestLength
        if (manifest == null && n != null && buffer.size >= n) {
            manifest =
                wireJson
                    .decodeFromString<BackupManifest>(
                        buffer.copyOfRange(0, n).toString(Charsets.UTF_8)
                    )
                    .also { m ->
                        m.snapshot.validate()
                        require(
                            m.snapshot.diaries.flatMap { it.media }.flatMap { it.files }.sorted() ==
                                m.files.map { it.name }
                        )
                        require(m.files.all { it.length in 40..512L * 1024 * 1024 })
                    }
            buffer = buffer.copyOfRange(n, buffer.size)
        }
        val m = manifest ?: return
        var offset = 0
        while (index < m.files.size && offset < buffer.size) {
            val file = m.files[index]
            if (output == null) output = File(directory, file.name).outputStream().buffered()
            val count = minOf((buffer.size - offset).toLong(), file.length - written).toInt()
            output!!.write(buffer, offset, count)
            offset += count
            written += count
            if (written == file.length) {
                output!!.close()
                output = null
                require(Backup.digest(File(directory, file.name)) == file.sha256)
                index++
                written = 0
            }
        }
        buffer = buffer.copyOfRange(offset, buffer.size)
    }

    fun finish(): Snapshot {
        val m = requireNotNull(manifest)
        require(index == m.files.size && written == 0L && buffer.isEmpty())
        return m.snapshot
    }

    override fun close() {
        output?.close()
    }
}
