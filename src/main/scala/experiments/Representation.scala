package experiments

object Representation {

    def encodeList(values : List[Int], cardinalities : List[Int]) : Int = {
        var result = 0
        var multiplier = 1
        for((value, cardinality) <- values.zip(cardinalities)) {
            result += value * multiplier
            multiplier *= cardinality
        }
        result
    }

    def decodeList(number : Int, cardinalities : List[Int]) : List[Int] = {
        var result = List[Int]()
        var mask = 1
        var multiplier = 1
        for(cardinality <- cardinalities) {
            mask *= cardinality
            result ::= (number % mask) / multiplier
            multiplier = mask
        }
        result.reverse
    }

    def main(args: Array[String]): Unit = {
        val cardinalities = List(10, 20, 15)
        val values = List(7, 4, 6)
        println(cardinalities)
        println(values)
        val number = encodeList(values, cardinalities)
        println(number)
        println(decodeList(number, cardinalities))
    }

}
