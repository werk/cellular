import IntCell.Cell
import Language._

/**
 * Ad hoc experiment with cell conversion in Scala to and from a 32 bit integer.
 */
class IntCell(cells : List[DCellType], traits : List[DTrait]) {

    def intToCell(int : Int) : Cell = {
        val cellIndex = int % cells.length
        val cellDeclaration = cells(cellIndex)
        Cell(
            cellDeclaration.name,
            Map()
        )
    }

    def cellToInt(cell : Cell) : Int = {
        val cellIndex = cells.zipWithIndex.collectFirst{ case (c, i) if c.name == cell.name => i}.get
        cellIndex
    }

}

object IntCell{
    case class Cell(
        name : String,
        traitValues : Map[String, Int]
    )

    def main(args : Array[String]) : Unit = {
        val converter = new IntCell(
            cells = List(
                DCellType("AIR", List(
                    CTrait("HEAT", Some(EVariable("x"))) -> Some(ENumber(5)),
                    CTrait("WEIGHT", Some(EPlus(EVariable("x"), EVariable("x")))) -> None)
                ),
                DCellType("SAND", List()),
                DCellType("WATER", List()),
            ),
            traits = List(
                DTrait("HEAT", TNumber(8)),
                DTrait("WEIGHT", TNumber(12))
            )
        )

        println(converter.intToCell(converter.cellToInt(Cell("AIR", Map()))))
        println(converter.intToCell(converter.cellToInt(Cell("SAND", Map()))))
        println(converter.intToCell(converter.cellToInt(Cell("WATER", Map()))))
    }
}
