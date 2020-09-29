package cellular.experiments

object IntToVec4 {

    def intToVec4(integer : Long) : (Float, Float, Float, Float) = {
        val o4 = 256 * 256 * 256
        val x4 = integer / o4
        val r4 = integer - (x4 * o4)
        val o3 = 256 * 256
        val x3 = r4 / o3
        val r3 = r4 - (x3 * o3)
        val o2 = 256
        val x2 = r3 / o2
        val r2 = r3 - (x2 * o2)
        val x1 = r2
        (x1.toFloat, x2.toFloat, x3.toFloat, x4.toFloat)
    }

    def vec4ToInt(vec4 : (Float, Float, Float, Float)) : Long = {
        val (f1, f2, f3, f4) = vec4
        val (x1, x2, x3, x4) = (f1.toLong, f2.toLong, f3.toLong, f4.toLong)
        x1 + 256 * (x2 + 256 * (x3 + 256 * (x4)))
    }

    def main(args : Array[String]) : Unit = {
        val max = 256L * 256L * 256L * 256L
        var i = 0L
        while(i < max) {
            if(i % 10_000_000 == 0) println(s"Tested $i/$max (${(i.toDouble/max * 1000).toInt.toDouble / 10}%)")
            val vec4 = intToVec4(i)
            val result = vec4ToInt(vec4)
            assert(i == result, s"failed for i = $i. vec4 = $vec4. result = $result")
            i += 1
        }
    }

}
