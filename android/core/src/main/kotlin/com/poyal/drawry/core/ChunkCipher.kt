package com.poyal.drawry.core

import java.io.*
import java.nio.ByteBuffer
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

object ChunkCipher {
    const val CHUNK_SIZE = 4 * 1024 * 1024

    fun random(count: Int) = ByteArray(count).also { SecureRandom().nextBytes(it) }

    fun uint32(value: Int): ByteArray = ByteBuffer.allocate(4).putInt(value).array()

    fun uint64(value: Long): ByteArray = ByteBuffer.allocate(8).putLong(value).array()

    fun seal(plain: ByteArray, key: ByteArray, nonce: ByteArray, aad: ByteArray): ByteArray =
        cipher(Cipher.ENCRYPT_MODE, key, nonce, aad).doFinal(plain)

    fun open(encrypted: ByteArray, key: ByteArray, nonce: ByteArray, aad: ByteArray): ByteArray =
        cipher(Cipher.DECRYPT_MODE, key, nonce, aad).doFinal(encrypted)

    private fun cipher(mode: Int, key: ByteArray, nonce: ByteArray, aad: ByteArray) =
        Cipher.getInstance("AES/GCM/NoPadding").apply {
            require(key.size == 32 && nonce.size == 12)
            init(mode, SecretKeySpec(key, "AES"), GCMParameterSpec(128, nonce))
            updateAAD(aad)
        }

    fun encrypt(source: File, destination: File, key: ByteArray, context: String) =
        source.inputStream().buffered().use {
            encrypt(it, source.length(), destination, key, context)
        }

    fun encrypt(
        input: InputStream,
        length: Long,
        destination: File,
        key: ByteArray,
        context: String,
    ) {
        require(key.size == 32 && length in 0 until CHUNK_SIZE.toLong() * 0xffff_ffffL)
        val header = "DRY2".toByteArray() + uint32(CHUNK_SIZE) + uint64(length) + random(8)
        var success = false
        try {
            destination.outputStream().buffered().use { output ->
                output.write(header)
                var remaining = length
                var index = 0
                while (true) {
                    if (Thread.currentThread().isInterrupted)
                        throw InterruptedIOException("Cancelled")
                    val count = minOf(CHUNK_SIZE.toLong(), remaining).toInt()
                    val plain = input.readExactly(count)
                    output.write(
                        seal(
                            plain,
                            key,
                            header.copyOfRange(16, 24) + uint32(index),
                            header + context.toByteArray(Charsets.UTF_8) + uint32(index),
                        )
                    )
                    if (count == 0) break
                    remaining -= count
                    index++
                }
            }
            success = true
        } finally {
            if (!success) destination.delete()
        }
    }

    fun decrypt(source: File, destination: File, key: ByteArray, context: String) {
        var success = false
        try {
            destination.outputStream().buffered().use { out ->
                decrypt(source, key, context) { out.write(it) }
            }
            success = true
        } finally {
            if (!success) destination.delete()
        }
    }

    fun decrypt(source: File, key: ByteArray, context: String, write: (ByteArray) -> Unit) {
        source.inputStream().buffered().use { input ->
            val header = input.readExactly(24)
            require(
                header.copyOfRange(0, 4).contentEquals("DRY2".toByteArray()) &&
                    ByteBuffer.wrap(header, 4, 4).int == CHUNK_SIZE
            )
            var remaining = ByteBuffer.wrap(header, 8, 8).long
            var index = 0
            require(remaining in 0 until CHUNK_SIZE.toLong() * 0xffff_ffffL)
            while (true) {
                if (Thread.currentThread().isInterrupted) throw InterruptedIOException("Cancelled")
                val count = minOf(CHUNK_SIZE.toLong(), remaining).toInt()
                val plain =
                    open(
                        input.readExactly(count + 16),
                        key,
                        header.copyOfRange(16, 24) + uint32(index),
                        header + context.toByteArray(Charsets.UTF_8) + uint32(index),
                    )
                if (count == 0) break
                write(plain)
                remaining -= count
                index++
            }
            require(input.read() == -1) { "Trailing data" }
        }
    }
}

fun InputStream.readExactly(count: Int): ByteArray {
    require(count >= 0)
    val bytes = ByteArray(count)
    var offset = 0
    while (offset < count) {
        val n = read(bytes, offset, count - offset)
        if (n < 0) throw EOFException()
        if (n == 0) continue
        offset += n
    }
    return bytes
}
