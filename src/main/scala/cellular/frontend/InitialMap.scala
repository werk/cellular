package cellular.frontend

import cellular.language.{Codec, Parser, TypeContext, Value}

import scala.scalajs.js.typedarray.Uint32Array

class InitialMap(context : TypeContext, width : Int, height : Int) {

    val array = new Uint32Array(width * height)

    private val imp = encode(read("Cave Foreground(Imp ImpStep(0) ImpClimb(None) DirectionH(Right) Content(None)) Background(None)"))
    private val box = encode(read("Building BuildingVariant(BigChest Content(RockOre) BigContentCount(0))"))
    private val cave = encode(read("Cave Foreground(None) Background(None)"))
    private val rock = encode(read("Rock Vein(RockOre) Light(0) Dig(0)"))
    private val sand = encode(read("Cave Foreground(Sand) Background(None)"))
    private val water = encode(read("Cave Foreground(Water) Background(None)"))
    private val wood = encode(read("Cave Foreground(Wood) Background(None)"))
    private val campfire = encode(read("Building BuildingVariant(Campfire CampfireFuel(100))"))

    private def set(x : Int, y : Int, integer : Long) = {
        val i = (y * width) + x
        array(i) = integer.toDouble
    }

    private def encode(value : Value) : Long = {
        Codec.encodeValue(context, context.properties("Tile"), value)
    }

    private def read(constructor : String) : Value = new Parser(constructor).parseValue()

    private def select(x : Int, y : Int) : Long = (x, y) match {
        case (7, 7) => imp
        case (5, 6) => box
        case (5, 3) => sand
        case (6, 3) => water
        case (7, 3) => wood
        case (8, 3) => campfire
        case (x, y) if 5 <= x && x <= 10 && 5 <= y && y <= 10 => cave
        case _ => rock
    }

    Range(0, height).foreach { y =>
        Range(0, width).foreach { x =>
            set(x, y, select(x, y))
        }
    }

}
