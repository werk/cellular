package cellular.frontend

import cellular.mini.{Codec, Parser, TypeContext, Value}

import scala.scalajs.js.typedarray.Uint32Array

class InitialMap(context : TypeContext, width : Int, height : Int) {

    val array = new Uint32Array(width * height)

    private val imp = encode(read("Cave Foreground(Imp ImpStep(0) ImpClimb(None) DirectionH(Right) Content(None)) Background(None)"))
    private val box = encode(read("Building BuildingVariant(BigChest Content(RockOre) BigContentCount(0))"))
    private val cave = encode(read("Cave Foreground(None) Background(None)"))
    private val rock = encode(read("Rock Vein(RockOre) Light(0) Dig(0)"))

    private def set(x : Int, y : Int, integer : Long) = {
        val i = (y * width) + x
        array(i) = integer.toDouble
    }

    private def encode(value : Value) : Long = {
        Codec.encodeValue(context, context.properties("Tile"), value)
    }

    private def read(constructor : String) : Value = new Parser(constructor).parseValue()

    private def select(x : Int, y : Int) : Long = (x, y) match {
        case (x, y) if 5 <= x && x <= 10 && 5 <= y && y <= 10 => cave
        case (7, 7) => imp
        case (5, 6) => box
        case _ => rock
    }

    Range(0, height).foreach { y =>
        Range(0, width).foreach { x =>
            set(x, y, select(x, y))
        }
    }

}
