package cellular.experiments

object HyperCube {

    def getAddress(boundsAndIndices : List[(Int, Int)]) : Int = boundsAndIndices match {
        case (_, index) :: List() => index
        case (bound, index) :: rest=> index + bound * getAddress(rest)
    }

    def getAddressExpression(dimensionsAndIndices : List[(Int, String)]) : String = dimensionsAndIndices match {
        case (_, index) :: List() => s"$index"
        case (bound, index) :: rest=> s"$index + $bound * (${getAddressExpression(rest)})"
    }

    def getIndices(dimensions : List[Int], address : Int) : List[Int] = dimensions match {
        case List() => List()
        case List(_) => List(address)
        case _ :: tail =>
            val offset = tail.product
            val y = address / offset
            val x = address - (y * offset)
            y :: getIndices(tail, x)
    }

    def getIndicesExpression(dimensionsWithIndices : List[(Int, Int)], address : String) : List[String] = dimensionsWithIndices match {
        case List() => List()
        case List((_, i)) =>
            List(s"x$i = $address")
        case (_, i) :: tail =>
            s"o$i = ${tail.map(_._1).mkString(" * ")}" ::
            s"x$i = $address / o$i" ::
            s"r$i = $address - (x$i * o$i)" ::
            getIndicesExpression(tail, s"r$i")
    }




    def main(args : Array[String]) : Unit = {
        val dimensions = List(5, 7, 9)
        val indices = List(3, 4, 6)
        val dimensionsAndIndices = dimensions.zip(indices)
        val address = getAddress(dimensionsAndIndices)

        println(getAddressExpression(dimensionsAndIndices.map{case (d, i) => d -> i.toString}) + " = " + address)

        println()
        println(getIndices(dimensions.reverse, address).reverse)

        println()
        getIndicesExpression(dimensions.zipWithIndex.reverse, "233").foreach(println)

        println()
        println("intToVec4:")
        getIndicesExpression(List(256 -> 4, 256 -> 3, 256 -> 2, 256 -> 1), "integer").foreach(println)

        println()
        println("vec4ToInt:")
        println(getAddressExpression(List(256 -> "x1", 256 -> "x2", 256 -> "x3", 256 -> "x4")))

        testBroodForce()
    }

    def testBroodForce() : Unit = {
        val dimensions = List(7, 11, 5, 17)
        for {
            x <- 1 until dimensions(0)
            y <- 1 until dimensions(1)
            z <- 1 until dimensions(2)
            w <- 1 until dimensions(3)
        } {
            val indices = List(x, y, z, w)
            val address = getAddress(dimensions.zip(indices))
            val indices2 = getIndices(dimensions.reverse, address).reverse
            if(indices != indices2) throw new RuntimeException(indices + " /= " + indices2)
        }

    }
}
