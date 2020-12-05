package cellular.mini

import cellular.mini.Parser._

class Parser(code: String) extends AbstractParser(code, List("property", "material")) {

    def parseDefinitions(): List[Definition] = {
        var definitions = List[Definition]()
        while(ahead().lexeme != LEnd) {
            definitions ::= parseDefinition()
        }
        definitions.reverse
    }

    def parseDefinition(): Definition = {
        val token = ahead()
        if(token.lexeme == LKeyword) {
            if(token.text == "property") parsePropertyDefinition()
            else if(token.text == "material") parseMaterialDefinition()
            else fail(token.line, "Expected definition, got " + token.lexeme + ": " + token.text)
        } else {
            fail(token.line, "Expected definition, got " + token.lexeme + ": " + token.text)
        }
    }

    def parsePropertyDefinition(): DProperty = {
        skipText("property")
        val nameToken = skip(LUpper)
        val fixedType = if(ahead().text != "(") None else Some {
            skipText("(")
            val t = parseType()
            skipText(")")
            var fixed = List[PropertyValue]()
            while(ahead().lexeme == LUpper) {
                val fixedNameToken = skip(LUpper)
                skipText("?")
                skipText("(")
                fixed ::= PropertyValue(fixedNameToken.text, parseValue())
                skipText(")")
            }
            FixedType(t, fixed.reverse)
        }
        DProperty(nameToken.text, fixedType)
    }

    def parseMaterialDefinition(): DMaterial = {
        skipText("material")
        val nameToken = skip(LUpper)
        var properties = List[MaterialProperty]()
        while(ahead().lexeme == LUpper) {
            val fixedNameToken = skip(LUpper)
            val value = if(ahead().text != "(") None else Some {
                skipText("(")
                val v = parseValue()
                skipText(")")
                v
            }
            properties ::= MaterialProperty(fixedNameToken.text, value)
        }
        DMaterial(nameToken.text, properties)
    }

    def parseType(): Type = {
        val left = if(ahead().text == "(") {
            skipText("(")
            val t = parseType()
            skipText(")")
            t
        } else {
            val nameToken = skip(LUpper)
            var names = List[Type](TProperty(nameToken.text))
            while(ahead().lexeme == LUpper) {
                val nameToken2 = skip(LUpper)
                names ::= TProperty(nameToken2.text)
            }
            names.reverse.reduce(TIntersection)
        }
        if(ahead().text == "|") {
            skipText("|")
            TUnion(left, parseType())
        }
        else left
    }

    def parseValue(): Value = {
        val nameToken = skip(LUpper)
        var properties = List[PropertyValue]()
        while(ahead().lexeme == LUpper) {
            val propertyNameToken = skip(LUpper)
            skipText("(")
            properties ::= PropertyValue(propertyNameToken.text, parseValue())
            skipText(")")
        }
        Value(nameToken.text, properties.reverse)
    }

}

object Parser {

    case class AbstractParser(code: String, keywords: List[String]) {
        private val tokens = tokenize(code, keywords)
        private var offset = 0

        protected def ahead() = if(offset >= tokens.length) Token("", LEnd, 0) else tokens(offset)
        protected def aheadAhead() = if(offset + 1 >= tokens.length) Token("", LEnd, 0) else tokens(offset + 1)
        protected def skip(lexeme: Lexeme): Token = {
            val result = ahead()
            if(result.lexeme != lexeme) {
                fail(result.line, "Expected " + lexeme + ", got " + result.lexeme + ": " + result.text)
            }
            offset += 1
            result
        }
        protected def skipText(text: String): Token = {
            val result = ahead()
            if(result.text != text) {
                fail(result.line, "Expected '" + text + "', got " + result.lexeme + ": " + result.text)
            }
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
    case object LKeyword extends Lexeme
    case object LSeparator extends Lexeme
    case object LOperator extends Lexeme
    case object LEnd extends Lexeme

    def tokenize(code: String, keywords: List[String]): Array[Token] = {
        val tokenPattern =
            """(?:[ \t]|[/][/].*|[/][*].*?[*][/])*(([A-Z][a-zA-Z0-9]*)|([a-z][a-zA-Z0-9]*)|([(){},.;:])|([-+*/^?!@#$%&|<>]+)|([\r]?[\n]|$)|.)""".r
        var line = 1
        tokenPattern.findAllMatchIn(code).map { m =>
            println(m.group(6) != null)
            if(m.group(6) != null) { line += 1; null }
            else if(m.group(2) != null) Token(m.group(1), LUpper, line)
            else if(m.group(3) != null && keywords.contains(m.group(3))) Token(m.group(1), LKeyword, line)
            else if(m.group(3) != null) Token(m.group(1), LLower, line)
            else if(m.group(4) != null) Token(m.group(1), LSeparator, line)
            else if(m.group(5) != null) Token(m.group(1), LOperator, line)
            else throw new RuntimeException("Unexpected token text: " + m.group(0) + " at or after line " + line)
        }.filter(_ != null).toArray
    }

    def main(args : Array[String]) : Unit = {
        val code = """
            property Weight(MaxThree)
            property Resource
            property Temperature(MaxThree)
            property Content(Resource) Temperature?(Zero) ChestCount?(Zero)
            property ChestCount(MaxThree)
            property Foreground(Resource | Imp | Air)
            property Background(Black | White)
            material Chest Content ChestCount Resource
            material Imp Content
            material Stone Resource Weight(Two)
            material IronOre Resource Temperature
            material Water Resource Temperature Weight(One)
            material Air Weight(Zero)
            material Tile Foreground Background
        """
        println(new Parser(code).parseDefinitions())
    }

}
