import java.nio.file.{Files, Paths}
import scala.io.Source

object Main {

    def main(arguments : Array[String]) : Unit = arguments match {
        case Array(in, out) =>
            val lines = Source.fromFile(in, "UTF-8").getLines().toList
            val declarations = Parser.parse(lines)
            TypeChecker.check(declarations)
            val program = Compile.compile(declarations)
            Files.write(Paths.get(out), program.getBytes("UTF-8"))
        case _ =>
            println("USAGE: Main input-file output-file")
            System.exit(1)
    }

}
