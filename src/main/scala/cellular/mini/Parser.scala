package cellular.mini

import cellular.mini.Parser._

class Parser(code: String) extends AbstractParser(code, List()) {

    def parseDefinitions(): List[Definition] = {
        var definitions = List[Definition]()
        while(ahead().lexeme != LEnd) {
            definitions ::= parseDefinition()
        }
        definitions.reverse
    }

    def parseDefinition(): Definition = {
        val token1 = ahead()
        val token2 = aheadAhead()
        (token1.text, token2.text) match {
            case ("[", "property") => parsePropertyDefinition()
            case ("[", "material") => parseMaterialDefinition()
            case ("[", "group") => parseGroupDefinition()
            case _ => fail(token1.line, "Expected definition, got " + token1.lexeme + ": " + token1.text)
        }
    }

    def parsePropertyDefinition(): DProperty = {
        skip("[")
        skip("property")
        skip("]")
        val nameToken = skipLexeme(LUpper)
        val fixedType = if(ahead().text != "(") None else Some {
            skip("(")
            val t = parseType()
            skip(")")
            var fixed = List[PropertyValue]()
            while(ahead().lexeme == LUpper) {
                val fixedNameToken = skipLexeme(LUpper)
                skip("?")
                skip("(")
                fixed ::= PropertyValue(fixedNameToken.text, parseValue())
                skip(")")
            }
            FixedType(t, fixed.reverse)
        }
        DProperty(nameToken.text, fixedType)
    }

    def parseMaterialDefinition(): DMaterial = {
        skip("[")
        skip("material")
        skip("]")
        val nameToken = skipLexeme(LUpper)
        var properties = List[MaterialProperty]()
        while(ahead().lexeme == LUpper) {
            val fixedNameToken = skipLexeme(LUpper)
            val value = if(ahead().text != "(") None else Some {
                skip("(")
                val v = parseValue()
                skip(")")
                v
            }
            properties ::= MaterialProperty(fixedNameToken.text, value)
        }
        DMaterial(nameToken.text, properties)
    }

    def parseGroupDefinition(): DGroup = {
        skip("[")
        skip("group")
        val nameToken = skipLexeme(LLower)
        val scheme = parseScheme()
        skip("]")
        var rules = List(parseRule())
        while(ahead().text == "[" && aheadAhead().text == "or") {
            skip("[")
            skip("or")
            skip("]")
            rules ::= parseRule()
        }
        DGroup(nameToken.text, scheme, rules.reverse)
    }

    def parseRule(): Rule = {
        val patterns = parsePatternMatrix()
        skipLexeme(LDashes)
        val nameToken = skipLexeme(LLower)
        val scheme = parseScheme()
        skip("->")
        val e = parseExpression()
        Rule(nameToken.text, scheme, patterns, e)
    }

    def parseScheme(): Scheme = {
        val wrapper = if(ahead().lexeme != LUpper) None else Some(skipLexeme(LUpper).text)
        var unless = List[String]()
        while(ahead().text == "!") {
            skip("!")
            unless ::= skipLexeme(LLower).text
        }
        var modifiers = List[String]()
        while(ahead().text == "@") {
            skip("@")
            modifiers ::= (
                if(ahead().text.headOption.exists(_.isDigit)) skipLexeme(LUpper).text
                else skipLexeme(LLower).text
            )
        }
        Scheme(wrapper, unless.reverse, modifiers.reverse)
    }

    def parseType(): Type = {
        val left = if(ahead().text == "(") {
            skip("(")
            val t = parseType()
            skip(")")
            t
        } else {
            val nameToken = skipLexeme(LUpper)
            var names = List[Type](TProperty(nameToken.text))
            while(ahead().lexeme == LUpper) {
                val nameToken2 = skipLexeme(LUpper)
                names ::= TProperty(nameToken2.text)
            }
            names.reverse.reduce(TIntersection)
        }
        if(ahead().text == "|") {
            skip("|")
            TUnion(left, parseType())
        }
        else left
    }

    def parseValue(): Value = {
        val nameToken = skipLexeme(LUpper)
        var properties = List[PropertyValue]()
        while(ahead().lexeme == LUpper) {
            val propertyNameToken = skipLexeme(LUpper)
            skip("(")
            properties ::= PropertyValue(propertyNameToken.text, parseValue())
            skip(")")
        }
        Value(nameToken.text, properties.reverse)
    }

    def parseExpression(): Expression = {
        var expressions = List(parseExpressionLine())
        while(ahead().text == ".") {
            skip(".")
            expressions ::= parseExpressionLine()
        }
        expressions match {
            case List(List(e)) => e
            case _ => EMatrix(expressions.reverse)
        }
    }

    def parseExpressionLine(): List[Expression] = {
        var expressions = List(parseMatch())
        while(ahead().text == ",") {
            skip(",")
            expressions ::= parseMatch()
        }
        expressions.reverse
    }

    def parseMatch(): Expression = {
        val left = parseBinaryOperator(0)
        if(ahead().text != ":") left else {
            skip(":")
            val p = if(ahead().text == "=>") PProperty(PVariable(None), "1", None) else parsePattern()
            skip("=>")
            val e = parseExpression()
            var cases = List[MatchCase](MatchCase(p, e))
            while(ahead().text == ";") {
                skip(";")
                val p1 = if(ahead().text == "=>") PProperty(PVariable(None), "0", None) else parsePattern()
                skip("=>")
                val e1 = parseExpression()
                cases ::= MatchCase(p1, e1)
            }
            EMatch(left, cases.reverse)
        }
    }

    def parseBinaryOperator(precedence: Int): Expression = if(precedence > 5) parseUpdate() else {
        var result = parseBinaryOperator(precedence + 1)
        while(getPrecedence(ahead().text).contains(precedence)) {
            val operatorToken = skipLexeme(LOperator)
            val right = parseBinaryOperator(precedence + 1)
            result = ECall(operatorToken.text, List(result, right))
        }
        result
    }

    def getPrecedence(operator: String) = operator match {
        case "||" => Some(1)
        case "&&" => Some(2)
        case "<" | ">" | "<=" | ">=" | "==" | "!=" => Some(3)
        case "+" | "-" => Some(4)
        case "*" | "/" => Some(5)
        case _ => None
    }

    def parseUpdate(): Expression = {
        var result = parseAtom()
        while(ahead().lexeme == LUpper) {
            val propertyToken = skipLexeme(LUpper)
            skip("(")
            val e = parseExpression()
            skip(")")
            result = EProperty(result, propertyToken.text, e)
        }
        result
    }

    def parseAtom(): Expression = {
        if(ahead().text == "(") {
            skip("(")
            val e = parseExpression()
            skip(")")
            e
        } else if(ahead().lexeme == LLower && aheadAhead().text == "(") {
            val nameToken = skipLexeme(LLower)
            skip("(")
            var arguments = List[Expression]()
            while(ahead().text != ")") {
                if(arguments.nonEmpty) skip(",")
                arguments ::= parseExpression()
            }
            skip(")")
            ECall(nameToken.text, arguments.reverse)
        } else if(ahead().text == "!" || ahead().text == "-") {
            val operatorToken = skipLexeme(LOperator)
            val e = parseUpdate()
            ECall(operatorToken.text, List(e))
        } else if(ahead().lexeme == LLower) {
            val nameToken = skipLexeme(LLower)
            EVariable(nameToken.text)
        } else if(ahead().lexeme == LUpper) {
            val nameToken = skipLexeme(LUpper)
            EMaterial(nameToken.text)
        } else {
            fail(ahead().line, "Expected atomic expression, got " + ahead().lexeme + ": " + ahead().text)
        }
    }

    def parsePatternMatrix(): List[List[Pattern]] = {
        var patterns = List(parsePatternLine())
        while(ahead().text == ".") {
            skip(".")
            patterns ::= parsePatternLine()
        }
        patterns.reverse
    }

    def parsePatternLine(): List[Pattern] = {
        var patterns = List(parsePattern())
        while(ahead().text == ",") {
            skip(",")
            patterns ::= parsePattern()
        }
        patterns.reverse
    }

    def parsePattern(): Pattern = {
        var result : Pattern = if(ahead().lexeme == LLower) {
            val nameToken = skipLexeme(LLower)
            PVariable(Some(nameToken.text))
        } else if(ahead().lexeme == LWildcard) {
            skipLexeme(LWildcard)
            PVariable(None)
        } else if(ahead().lexeme == LUpper) {
            PVariable(None)
        } else {
            fail(ahead().line, "Expected pattern, got " + ahead().lexeme + ": " + ahead().text)
        }
        while(ahead().lexeme == LUpper) {
            val nameToken = skipLexeme(LUpper)
            val pattern = if(ahead().text == "(") {
                skip("(")
                val p = parsePattern()
                skip(")")
                Some(p)
            } else None
            result = PProperty(result, nameToken.text, pattern)
        }
        result
    }

}

object Parser {

    case class AbstractParser(code: String, keywords: List[String]) {
        private val tokens = tokenize(code, keywords)
        private var offset = 0

        protected def ahead() = if(offset >= tokens.length) Token("", LEnd, 0) else tokens(offset)
        protected def aheadAhead() = if(offset + 1 >= tokens.length) Token("", LEnd, 0) else tokens(offset + 1)
        protected def skipLexeme(lexeme: Lexeme): Token = {
            val result = ahead()
            if(result.lexeme != lexeme) {
                fail(result.line, "Expected " + lexeme + ", got " + result.lexeme + ": " + result.text)
            }
            offset += 1
            result
        }
        protected def skip(text: String): Token = {
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
    case object LWildcard extends Lexeme
    case object LKeyword extends Lexeme
    case object LSeparator extends Lexeme
    case object LOperator extends Lexeme
    case object LDashes extends Lexeme
    case object LEnd extends Lexeme

    def tokenize(code: String, keywords: List[String]): Array[Token] = {
        val tokenPattern =
            """(?:[ \t]|[/][/].*|[/][*].*?[*][/])*(([A-Z][a-zA-Z0-9]*)|([a-z][a-zA-Z0-9]*)|([0-9]+)|([_])|([(){}\[\],.;:])|([-+*/^?!@#$%&|=<>]+)|([\r]?[\n]|$)|.)""".r
        var line = 1
        tokenPattern.findAllMatchIn(code).map { m =>
            if(m.group(8) != null) { line += 1; null }
            else if(m.group(2) != null) Token(m.group(1), LUpper, line)
            else if(m.group(3) != null && keywords.contains(m.group(3))) Token(m.group(1), LKeyword, line)
            else if(m.group(3) != null) Token(m.group(1), LLower, line)
            else if(m.group(4) != null) Token(m.group(1), LUpper, line)
            else if(m.group(5) != null) Token(m.group(1), LWildcard, line)
            else if(m.group(6) != null) Token(m.group(1), LSeparator, line)
            else if(m.group(7) != null) {
                if(m.group(7).length >= 2 && m.group(7).forall(_ == '-')) Token(m.group(1), LDashes, line)
                else Token(m.group(1), LOperator, line)
            }
            else throw new RuntimeException("Unexpected token text: " + m.group(0) + " at or after line " + line)
        }.filter(_ != null).toArray
    }

    def main(args : Array[String]) : Unit = {
        val code = """
            [property] Weight(MaxThree)
            [property] Resource
            [property] Temperature(MaxThree)
            [property] Content(Resource) Temperature?(Zero) ChestCount?(Zero)
            [property] ChestCount(MaxThree)
            [property] Foreground(Resource | Imp | Air)
            [property] Background(Black | White)
            [material] Chest Content ChestCount Resource
            [material] Imp Content
            [material] Stone Resource Weight(Two)
            [material] IronOre Resource Temperature
            [material] Water Resource Temperature Weight(One)
            [material] Air Weight(Zero)
            [material] Tile Foreground Background

            [group fallGroup]

            a Weight(x).
            b Weight(y)
            ------------ fall Foreground @h @v @90 @270 @180 ->
            x > y :=>
            b.
            a

            [group chestGroup !fallGroup]

            a Resource.
            b Chest Content(a) ChestCount(c)
            -------------------------------- fillChest Foreground ->
            c < 3 :=>
            Air.
            b Count(c + 1)

            [or]

            x Foreground(a Resource) Background(White).
            y Foreground(b Chest Content(a) ChestCount(c))
            ---------------------------------------------- fillChest2 ->
            x Foreground(Air).
            y Foreground(b Count(c + 1))

            [or]

            a Resource.
            b Chest Content(a) ChestCount(c)
            -------------------------------- fillChest ->
            c < 3 :=>
            Air.
            b Count(c + 1)
        """
        println(new Parser(code).parseDefinitions())
    }

}
