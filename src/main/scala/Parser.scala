import Language._

object Parser {

    case class Line(
        line : String,
        position : Int
    )

    case class ReactionLines(
        above : List[Line],
        arrow : Line,
        below : List[Line],
    )

    def parse(lines : List[String]) : List[Declaration] = {
        val linesWithNumbers = lines.zipWithIndex.map {case (line, i) => Line(line, i) }

        val traits = linesWithNumbers.takeWhile(line =>
            line.line.trim.isEmpty || line.line.startsWith(":")
        )

        val cellTypes = linesWithNumbers.drop(traits.size).takeWhile(line =>
            line.line.trim.isEmpty || !line.line.startsWith("[")
        )

        val groups = linesWithNumbers.drop(traits.size + cellTypes.size)

        traits.map(parseTrait) ++
            cellTypes.map(parseDellTypes) ++
            parseGroups(groups)

    }

    def parseTrait(line : Line) : DTrait = {
        ???
    }

    def parseDellTypes(line : Line) : DCellType = {
        ???
    }

    def parseGroups(lines : List[Line]) : List[DGroup] = lines.dropWhile {_.line.trim.isEmpty} match {
        case List() => List()
        case header :: rest if header.line.startsWith("[") =>
            val body = rest.takeWhile(!_.line.startsWith("["))
            val other = rest.drop(body.size)
            parseGroup(header, body) :: parseGroups(other)
        case first :: _ => fail(first, "Group header expected")
    }

    def parseGroup(header : Line, body : List[Line]) : DGroup = {
        val rules = splitByEmptyLines(body)
        ???
    }


    def splitByEmptyLines(lines : List[Line]) : List[List[Line]] = lines.dropWhile {_.line.trim.isEmpty} match {
        case List() => List()
        case lines =>
            val taken = lines.takeWhile {_.line.trim.nonEmpty}
            taken :: splitByEmptyLines(taken.drop(taken.length))
    }

    def fail(line : Line, error : String) : Nothing = {
        println(error)
        println(s"At line ${line.position}:")
        println(line.line)
        System.exit(1)
        throw new RuntimeException("")
    }

}
