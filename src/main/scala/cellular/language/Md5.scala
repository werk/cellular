package cellular.language

import java.nio.ByteBuffer
import java.nio.ByteOrder

// Implementation by chatgpt as java.security.MessageDigest is not supported in Scala.js
object Md5 {
    // Initial constants (A, B, C, D) – MD5 “magic” constants
    private val A0 = 0x67452301
    private val B0 = 0xEFCDAB89
    private val C0 = 0x98BADCFE
    private val D0 = 0x10325476

    // Sine-table T[i] = floor(2^32 * abs(sin(i+1))) for i=0..63
    private val T: Array[Int] = Array(
        0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
        0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
        0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
        0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
        0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
        0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
        0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
        0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
        0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
        0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
        0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
        0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
        0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
        0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
        0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
        0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391
    )

    // F, G, H, I MD5 auxiliary functions
    private def F(x: Int, y: Int, z: Int): Int = (x & y) | (~x & z)
    private def G(x: Int, y: Int, z: Int): Int = (x & z) | (y & ~z)
    private def H(x: Int, y: Int, z: Int): Int = x ^ y ^ z
    private def I(x: Int, y: Int, z: Int): Int = y ^ (x | ~z)

    // Left-rotate x by n bits
    private def rotateLeft(x: Int, n: Int): Int = (x << n) | (x >>> (32 - n))

    private def FF(a: Int, b: Int, c: Int, d: Int, x: Int, t: Int, s: Int): Int = {
        val tmp = a + F(b, c, d) + x + t
        b + rotateLeft(tmp, s)
    }

    private def GG(a: Int, b: Int, c: Int, d: Int, x: Int, t: Int, s: Int): Int = {
        val tmp = a + G(b, c, d) + x + t
        b + rotateLeft(tmp, s)
    }

    private def HH(a: Int, b: Int, c: Int, d: Int, x: Int, t: Int, s: Int): Int = {
        val tmp = a + H(b, c, d) + x + t
        b + rotateLeft(tmp, s)
    }

    private def II(a: Int, b: Int, c: Int, d: Int, x: Int, t: Int, s: Int): Int = {
        val tmp = a + I(b, c, d) + x + t
        b + rotateLeft(tmp, s)
    }

    // Converts the length (in bits) to 64-bit (8 bytes) little-endian.
    private def lengthToBytesLittleEndian(len: Long): Array[Byte] = {
        val buffer = ByteBuffer.allocate(8).order(ByteOrder.LITTLE_ENDIAN)
        buffer.putLong(len)
        buffer.array()
    }

    /**
     *  Returns the raw 16 bytes of the MD5 digest (little-endian words A,B,C,D).
     */
    def md5Bytes(input: String): Array[Byte] = {
        val originalBytes = input.getBytes("UTF-8")
        val bitLength = originalBytes.length.toLong * 8

        // Compute padding
        val mod64 = originalBytes.length % 64
        val padLength =
            if (mod64 < 56) 56 - mod64
            else 64 - mod64 + 56

        val padding = new Array[Byte](padLength + 8)
        // 0x80 = 10000000
        padding(0) = 0x80.toByte
        // put original length in bits at the end, little-endian
        val lengthBytes = lengthToBytesLittleEndian(bitLength)
        System.arraycopy(lengthBytes, 0, padding, padLength, 8)

        val message = originalBytes ++ padding

        // Initialize buffers
        var A = A0
        var B = B0
        var C = C0
        var D = D0

        // Process each 512-bit block
        val blockCount = message.length / 64
        for (i <- 0 until blockCount) {
            val blockStart = i * 64
            val X = new Array[Int](16)

            for (j <- 0 until 16) {
                val idx = blockStart + j*4
                X(j) = (message(idx) & 0xff) |
                    ((message(idx + 1) & 0xff) << 8) |
                    ((message(idx + 2) & 0xff) << 16) |
                    ((message(idx + 3) & 0xff) << 24)
            }

            var a = A
            var b = B
            var c = C
            var d = D

            // Round 1
            a = FF(a, b, c, d, X( 0), T( 0),  7)
            d = FF(d, a, b, c, X( 1), T( 1), 12)
            c = FF(c, d, a, b, X( 2), T( 2), 17)
            b = FF(b, c, d, a, X( 3), T( 3), 22)
            a = FF(a, b, c, d, X( 4), T( 4),  7)
            d = FF(d, a, b, c, X( 5), T( 5), 12)
            c = FF(c, d, a, b, X( 6), T( 6), 17)
            b = FF(b, c, d, a, X( 7), T( 7), 22)
            a = FF(a, b, c, d, X( 8), T( 8),  7)
            d = FF(d, a, b, c, X( 9), T( 9), 12)
            c = FF(c, d, a, b, X(10), T(10), 17)
            b = FF(b, c, d, a, X(11), T(11), 22)
            a = FF(a, b, c, d, X(12), T(12),  7)
            d = FF(d, a, b, c, X(13), T(13), 12)
            c = FF(c, d, a, b, X(14), T(14), 17)
            b = FF(b, c, d, a, X(15), T(15), 22)

            // Round 2
            a = GG(a, b, c, d, X( 1), T(16),  5)
            d = GG(d, a, b, c, X( 6), T(17),  9)
            c = GG(c, d, a, b, X(11), T(18), 14)
            b = GG(b, c, d, a, X( 0), T(19), 20)
            a = GG(a, b, c, d, X( 5), T(20),  5)
            d = GG(d, a, b, c, X(10), T(21), 9)
            c = GG(c, d, a, b, X(15), T(22), 14)
            b = GG(b, c, d, a, X( 4), T(23), 20)
            a = GG(a, b, c, d, X( 9), T(24),  5)
            d = GG(d, a, b, c, X(14), T(25), 9)
            c = GG(c, d, a, b, X( 3), T(26), 14)
            b = GG(b, c, d, a, X( 8), T(27), 20)
            a = GG(a, b, c, d, X(13), T(28), 5)
            d = GG(d, a, b, c, X( 2), T(29), 9)
            c = GG(c, d, a, b, X( 7), T(30), 14)
            b = GG(b, c, d, a, X(12), T(31), 20)

            // Round 3
            a = HH(a, b, c, d, X( 5), T(32),  4)
            d = HH(d, a, b, c, X( 8), T(33), 11)
            c = HH(c, d, a, b, X(11), T(34), 16)
            b = HH(b, c, d, a, X(14), T(35), 23)
            a = HH(a, b, c, d, X( 1), T(36),  4)
            d = HH(d, a, b, c, X( 4), T(37), 11)
            c = HH(c, d, a, b, X( 7), T(38), 16)
            b = HH(b, c, d, a, X(10), T(39), 23)
            a = HH(a, b, c, d, X(13), T(40),  4)
            d = HH(d, a, b, c, X( 0), T(41), 11)
            c = HH(c, d, a, b, X( 3), T(42), 16)
            b = HH(b, c, d, a, X( 6), T(43), 23)
            a = HH(a, b, c, d, X( 9), T(44),  4)
            d = HH(d, a, b, c, X(12), T(45), 11)
            c = HH(c, d, a, b, X(15), T(46), 16)
            b = HH(b, c, d, a, X( 2), T(47), 23)

            // Round 4
            a = II(a, b, c, d, X( 0), T(48),  6)
            d = II(d, a, b, c, X( 7), T(49), 10)
            c = II(c, d, a, b, X(14), T(50), 15)
            b = II(b, c, d, a, X( 5), T(51), 21)
            a = II(a, b, c, d, X(12), T(52),  6)
            d = II(d, a, b, c, X( 3), T(53), 10)
            c = II(c, d, a, b, X(10), T(54), 15)
            b = II(b, c, d, a, X( 1), T(55), 21)
            a = II(a, b, c, d, X( 8), T(56),  6)
            d = II(d, a, b, c, X(15), T(57), 10)
            c = II(c, d, a, b, X( 6), T(58), 15)
            b = II(b, c, d, a, X(13), T(59), 21)
            a = II(a, b, c, d, X( 4), T(60),  6)
            d = II(d, a, b, c, X(11), T(61), 10)
            c = II(c, d, a, b, X( 2), T(62), 15)
            b = II(b, c, d, a, X( 9), T(63), 21)

            // Update chunk results
            A += a
            B += b
            C += c
            D += d
        }

        // Convert (A, B, C, D) to a 16-byte array in little-endian order
        val resultBuffer = ByteBuffer.allocate(16).order(ByteOrder.LITTLE_ENDIAN)
        resultBuffer.putInt(A)
        resultBuffer.putInt(B)
        resultBuffer.putInt(C)
        resultBuffer.putInt(D)

        resultBuffer.array()
    }

    /**
     * Convenience method: returns the MD5 as a 32-char hex string.
     */
    def md5(input: String): String = {
        md5Bytes(input).map { byte =>
            f"$byte%02x"
        }.mkString
    }

    // Simple test
    def main(args: Array[String]): Unit = {
        val testStr = "abc"
        val hashBytes = md5Bytes(testStr)
        val hashHex   = md5(testStr)

        println(s"MD5('$testStr') as bytes = " + hashBytes.map("%02x".format(_)).mkString("[", ",", "]"))
        println(s"MD5('$testStr') as hex   = $hashHex")
        // Expect "900150983cd24fb0d6963f7d28e17f72"
    }
}

