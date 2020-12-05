package cellular.mini

import cellular.mini.Parser._

class Parser(code: String) extends AbstractParser(code) {



}

object Parser {

    case class AbstractParser(code: String) {
        private val tokens = tokenize(code)
        private var offset = 0

        protected def ahead() = if(offset >= tokens.length) Token("", LEnd, 0) else tokens(offset)
        protected def aheadAhead() = if(offset + 1 >= tokens.length) Token("", LEnd, 0) else tokens(offset + 1)
        protected def skip(lexeme: Lexeme): Token = {
            val result = ahead()
            if(result.lexeme != lexeme) fail(result.line, "Unexpected lexeme: " + result.text)
            offset += 1
            result
        }
        protected def fail(line: Int, message: String) = {
            throw new RuntimeException(message + " at line " + line)
        }
    }

    case class Token(text: String, lexeme: Lexeme, line: Int)

    sealed abstract class Lexeme
    case object LUpper extends Lexeme
    case object LLower extends Lexeme
    case object LSeparator extends Lexeme
    case object LOperator extends Lexeme
    case object LEnd extends Lexeme

    def tokenize(code: String): Array[Token] = {
        val tokenPattern =
            """(?:[ \t]|[/][/].*|[/][*].*?[*][/])*(([A-Z][a-zA-Z0-9]*)|([a-z][a-zA-Z0-9]*)|([(){},.;:])|([-+*/^?!@#$%&|<>]+)|([\r]?[\n]))""".r
        var line = 1
        tokenPattern.findAllMatchIn(code).map { m =>
            println(m.group(6) != null)
            if(m.group(6) != null) { line += 1; null }
            else if(m.group(2) != null) Token(m.group(1), LUpper, line)
            else if(m.group(3) != null) Token(m.group(1), LLower, line)
            else if(m.group(4) != null) Token(m.group(1), LSeparator, line)
            else if(m.group(5) != null) Token(m.group(1), LOperator, line)
            else throw new RuntimeException("Unexpected token text: " + m.group(0))
        }.filter(_ != null).toArray
    }

    def main(args : Array[String]) : Unit = {
        val code = """
            property Weight(MaxThree)
            property Resource
            property Temperature(MaxThree)
            property Content(Resource) Temperature?(Zero) ChestCount?(Zero)
            property ChestCount(MaxThree)
            property Foreground(Resource / Imp / Air)
            property Background(Black / White)
            material Chest Content ChestCount Resource
            material Imp Content
            material Stone Resource Weight(Two)
            material IronOre Resource Temperature
            material Water Resource Temperature Weight(One)
            material Air Weight(Zero)
            material Tile Foreground Background

            Foreground:    // Syntactic sugar for wrapping in Forground(...)
            a Weight(x).
            b Weight(y)
            -- x > y ->
            b.
            a

            a Resource.
            b Chest Content(a) ChestCount(c)
            -- c < 3 ->
            Air.
            b Count(c + 1)

            x Foreground(a Resource) Background(White).
            y Foreground(b Chest Content(a) ChestCount(c))
            -- c < 3 ->
            x Foreground(Air).
            y Foreground(b Count(c + 1))
        """
        println(tokenize(code).mkString("\n"))
    }

}
