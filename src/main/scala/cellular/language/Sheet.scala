package cellular.language

import Sheet._

class Sheet(val size : Int) {

    if(size > 26) throw new RuntimeException("Sheet size can't exceed 26, was: " + size)
    if(size < 2) throw new RuntimeException("Sheet size must be at least 2, was: " + size)
    if(size % 2 != 0) throw new RuntimeException("Sheet size must be even, was: " + size)

    private val (maxWidth, maxHeight) = (size, size)

    val sheetMatrix = Matrix(
        (0 until maxHeight).toList.map { y =>
            (0 until maxWidth).toList.map { x =>
                toCell(x, y)
            }
        }
    )

    def makeArgumentMatrix(width : Int, height : Int) : Matrix[Int] = {
        val x1 = (maxWidth - width) / 2
        val x2 = x1 + width - 1
        val y1 = (maxHeight - height) / 2
        val y2 = y1 + height - 1
        var i = 0
        Matrix(
            (0 until maxHeight).toList.map { y =>
                (0 until maxWidth).toList.map { x =>
                    if(x1 <= x && x <= x2 && y1 <= y && y <= y2) {
                        i += 1
                        i
                    } else {
                        0
                    }
                }
            }
        )
    }

    def makeReplicatedArgumentMatrices(width : Int, height : Int) : List[Matrix[Int]] = {
        val m = makeArgumentMatrix(width, height).cells
        List(Matrix(m)) ++
        List(Matrix(m.map(cycle))).filter(_ => width % 2 == 1) ++
        List(Matrix(cycle(m))).filter(_ => height % 2 == 1) ++
        List(Matrix(cycle(m.map(cycle)))).filter(_ => width % 2 == 1 && height % 2 == 1)
    }

    def makeModifiedArgumentMatrices(
        width : Int,
        height : Int,
        modifiers : List[String]
    ) : Either[String, List[(Int, Matrix[Int])]] = {
        val matrices = makeReplicatedArgumentMatrices(width, height)
        val result = for {
            modifier <- "" :: modifiers
            matrix <- matrices.map(_.cells)
        } yield modifier match {
            case "" =>
                0 -> Matrix(matrix)
            case "h" =>
                1 -> Matrix(matrix.map(_.reverse))
            case "v" =>
                2 -> Matrix(matrix.reverse)
            case "90" =>
                90 -> Matrix(matrix.map(_.reverse).transpose)
            case "180" =>
                180 -> Matrix(matrix.map(_.reverse).transpose.map(_.reverse).transpose)
            case "270" =>
                270 -> Matrix(matrix.map(_.reverse).transpose.map(_.reverse).transpose.map(_.reverse).transpose)
            case _ =>
                return Left("Unknown modifier: " + modifier)
        }
        if(result.size != result.distinct.size) {
            return Left("Redundant modifiers: " + modifiers)
        }
        Right(result)
    }

    def makeCellArguments(
        width : Int,
        height : Int,
        modifiers : List[String]
    ) : Either[String, List[(Int, List[String])]] = {
        val modified = makeModifiedArgumentMatrices(width, height, modifiers)
        modified.map { matrices =>
            matrices.map { case (modifier, matrix) =>
                modifier -> matrix.cells.zipWithIndex.flatMap { case (row, y) =>
                    row.zipWithIndex.map { case (i, x) =>
                        i -> sheetMatrix.cells(y)(x)
                    }
                }.filter(_._1 > 0).sortBy(_._1).map(_._2)
            }
        }
    }

    def computeCenterCells() : List[String] = {
        val center = makeCellArguments(2, 2, List())
        center.toOption.get.head._2
    }

    def computeCellOffsets[T](matrix : List[List[T]]) : Matrix[(String, T, Boolean)] = {
        val baseX = (maxWidth - matrix.head.size) / 2
        val baseY = (maxHeight - matrix.size) / 2

        val writeMinX = (matrix.head.size - 1) / 2
        val writeMinY = (matrix.size - 1) / 2
        val writeMaxX = matrix.head.size / 2
        val writeMaxY = matrix.size / 2

        Matrix(
            matrix.zipWithIndex.map { case (ps, y) =>
                ps.zipWithIndex.map { case (p, x) =>
                    val cell = toCell(baseX + x, baseY + y)
                    val writeX = x >= writeMinX && x <= writeMaxX
                    val writeY = y >= writeMinY && y <= writeMaxY
                    (cell, p, writeX && writeY)
                }
            }
        )
    }

}

object Sheet {

    case class Matrix[T](cells : List[List[T]]) {
        override def toString = cells.map(_.mkString(" ")).mkString("\n")
    }

    def autoSize[T](matrices : List[List[T]]*) : Sheet = {
        val max = matrices.map { m =>
            val width = m.head.size
            val height = m.size
            Math.max(width, height)
        }.max
        new Sheet(if(max % 2 == 1) max + 1 else max)
    }

    def toCell(x : Int, y : Int) = ('a' + x).toChar + (y + 1).toString
    def fromCell(cell : String) = (cell.head - 'a', cell.tail.toInt - 1)

    def cycle[T](list : List[T]) : List[T] = list.last :: list.init

    def modifierToInt(modifier : String) : Int = (modifier match {
        case "" => 0
        case "h" => 1
        case "v" => 2
        case rotation => rotation.toInt
    })

    def main(args : Array[String]) : Unit = {
        val (width, height) = (3, 2)
        val modifiers = List("270")
        println(List(1, 2, 3) + " cycles to " + cycle(List(1, 2, 3)))
        println("---")
        val sheet = new Sheet(6)
        println(sheet.sheetMatrix)
        println("---")
        val argumentMatrix = sheet.makeArgumentMatrix(width, height)
        println(argumentMatrix)
        println("---")
        val replicatedArgumentMatrices = sheet.makeReplicatedArgumentMatrices(width, height)
        println(replicatedArgumentMatrices.mkString("\n\n"))
        println("---")
        val modifiedArgumentMatrices = sheet.makeModifiedArgumentMatrices(width, height, modifiers)
        println(modifiedArgumentMatrices.toOption.get.mkString("\n\n"))
        println("---")
        val cellArguments = sheet.makeCellArguments(width, height, modifiers)
        println(cellArguments.toOption.get.map(_._2.mkString(", ")).mkString("\n"))
        println("---")
    }

}
