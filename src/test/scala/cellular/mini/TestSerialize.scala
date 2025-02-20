package cellular.mini

import cellular.mini.{Codec, Parser, TypeContext, Value}

import scala.io.Source

object TestSerialize {

    def main(arguments: Array[String]): Unit = {
        val Array(cellularPath) = arguments
        val cellular = Source.fromFile(cellularPath).mkString
        val definitions = new Parser(cellular).parseDefinitions()
        val context = TypeContext.fromDefinitions(definitions)

        def read(constructor: String): Value = new Parser(constructor).parseValue()

        def encode(value: Value): Long = {
            Codec.encodeValue(context, context.properties("Tile"), value)
        }

        def decode(integer: Long): Value = {
            Codec.decodeValue(context, context.properties("Tile"), integer.toInt)
        }

        val sand = encode(read("Cave Foreground(Sand) Background(None)"))

        context.materials.foreach { case (m, ps) => println(s"$m -> $ps") }
        //context.properties.foreach { case (m, ps) => println(s"$m -> $ps") }
        println

        val value = decode(sand)
        println(value.toString)
        println(show(value, context))
    }

    def show(value: Value, context: TypeContext) : String = {
        //println(value.material)
        val m = context.materials.getOrElse(value.material, List())
        val map = m.map { mp => mp.property -> mp.value}.toMap
        val informativeProperties = value.properties.filter { p =>
            map.get(p.property).exists(o => o.isEmpty)
        }
        value.material + informativeProperties.map { p =>
            " " + p.property + "(" + show(p.value, context) + ")"
        }.mkString
    }
}
