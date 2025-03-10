package cellular.language

import cellular.language.Parser._

class Parser(code: String) extends AbstractParser(code, List()) {

    def parseDefinitions(): List[Definition] = {
        var definitions = List[Definition]()
        while(ahead().lexeme != LEnd) {
            for(d <- parseDefinition()) definitions ::= d
        }
        definitions.reverse
    }

    def parseDefinition(): List[Definition] = {
        val token1 = ahead()
        val token2 = aheadAhead()
        (token1.text, token2.text) match {
            case ("[", "properties") =>
                parseUpperDefinitions("properties", parsePropertyDefinition)
            case ("[", "materials") =>
                parseUpperDefinitions("materials", parseMaterialDefinition)
            case ("[", "types") =>
                parseUpperDefinitions("types", parseTypeDefinition)
            case ("[", "function") =>
                List(parseFunctionDefinition())
            case ("[", "group") =>
                List(parseGroupDefinition())
            case _ => fail(token1.line, "Expected definition, got " + token1.lexeme + ": " + token1.text)
        }
    }

    def parseUpperDefinitions(keyword: String, parse: () => Definition): List[Definition] = {
        skip("[")
        skip(keyword)
        skip("]")
        var definitions = List[Definition]()
        while(ahead().lexeme == LUpper) {
            definitions ::= parse()
        }
        definitions.reverse
    }

    def parsePropertyDefinition(): DProperty = {
        val nameToken = skipLexeme(LUpper)
        skip("(")
        val t = parseType()
        skip(")")
        var fixed = List[PropertyValue]()
        if(ahead().text == "{") {
            skip("{")
            while(ahead().lexeme == LUpper) {
                val fixedNameToken = skipLexeme(LUpper)
                skip("?")
                skip("(")
                fixed ::= PropertyValue(fixedNameToken.line, fixedNameToken.text, parseValue())
                skip(")")
            }
            skip("}")
        }
        val fixedType = FixedType(t.line, t, fixed.reverse)
        DProperty(nameToken.line, nameToken.text, fixedType)
    }

    def parseMaterialDefinition(): DMaterial = {
        val nameToken = skipLexeme(LUpper)
        var properties = List[MaterialProperty]()
        if(ahead().text == "{") {
            skip("{")
            while(ahead().lexeme == LUpper) {
                val fixedNameToken = skipLexeme(LUpper)
                val value = if(ahead().text != "(") None else Some {
                    skip("(")
                    val v = parseValue()
                    skip(")")
                    v
                }
                properties ::= MaterialProperty(fixedNameToken.line, fixedNameToken.text, value)
            }
            skip("}")
        }
        DMaterial(nameToken.line, nameToken.text, properties)
    }

    def parseTypeDefinition(): DType = {
        val nameToken = skipLexeme(LUpper)
        skip("=")
        val t = parseType()
        skip(".")
        DType(nameToken.line, nameToken.text, t)
    }

    def parseFunctionDefinition(): DFunction = {
        skip("[")
        skip("function")
        val nameToken = skipLexeme(LLower)
        skip("(")
        var parameters = List[Parameter]()
        while(ahead().text != ")") {
            val parameterNameToken = skipLexeme(LLower)
            val parameterKind = parseKind()
            parameters ::= Parameter(parameterNameToken.line, parameterNameToken.text, parameterKind)
            if(ahead().text != ")") skip(",")
        }
        skip(")")
        val returnKind = parseKind()
        skip("]")
        val body = parseExpression()
        DFunction(nameToken.line, nameToken.text, parameters.reverse, returnKind, body)
    }

    def parseKind(): Kind = {
        val kindName = skipLexeme(LLower)
        kindName.text match {
            case "bool" => KBool
            case "uint" => KNat
            case "value" => KValue
            case _ => fail(kindName.line, "No such kind: " + kindName.text)
        }
    }

    def parseGroupDefinition(): DGroup = {
        skip("[")
        skip("group")
        val nameToken = skipLexeme(LLower)
        val scheme = parseScheme(nameToken.line)
        skip("]")
        var rules = List[Rule]()
        while(ahead().text == "[" && aheadAhead().text == "rule") {
            rules ::= parseRule()
        }
        DGroup(nameToken.line, nameToken.text, scheme, rules.reverse)
    }

    def parseRule(): Rule = {
        skip("[")
        skip("rule")
        val nameToken = skipLexeme(LLower)
        val scheme = parseScheme(nameToken.line)
        skip("]")
        val patterns = parsePatternMatrix()
        skip("--")
        val e = parseExpression()
        val rule = Rule(nameToken.line, nameToken.text, scheme, patterns, e)
        fixPatternMatrix(rule)
    }

    def fixPatternMatrix(rule: Rule): Rule = {
        var seen = Set[String]()
        var checks = List[(Int, String, String)]()
        var nextVariable = 1
        def fixPattern(pattern: Pattern): Pattern = {
            val newName = pattern.name.map { name =>
                if(seen(name)) {
                    val freshName = "p_" + nextVariable
                    nextVariable += 1
                    checks ::= ((pattern.line, freshName, name))
                    freshName
                } else {
                    seen += name
                    name
                }
            }
            val newSymbols = pattern.symbols.map(s => s.copy(pattern = s.pattern.map(fixPattern)))
            pattern.copy(name = newName, symbols = newSymbols)
        }
        val newPatterns = rule.patterns.map(_.map(fixPattern))
        val newExpression = if(checks.isEmpty) rule.expression else {
            val check = checks.reverse.map { case (line, x1, x2) =>
                ECall(line, KUnknown, "===", List(
                    EVariable(line, KUnknown, x1),
                    EVariable(line, KUnknown, x2)
                ))
            }.reduce { (e1, e2) => ECall(rule.line, KUnknown, "&&", List(e1, e2)) }
            EMatch(rule.line, KUnknown, check, List(MatchCase(rule.line,
                Pattern(rule.line, KUnknown, None, List(SymbolPattern(rule.line, "1", None))),
            rule.expression)))
        }
        rule.copy(patterns = newPatterns, expression = newExpression)
    }

    def parseScheme(line: Int): Scheme = {
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
        val expandedModifiers = modifiers.reverse.flatMap {
            case "r" => List("90", "180", "270")
            case modifier => List(modifier)
        }
        Scheme(line, wrapper, unless.reverse, expandedModifiers)
    }

    def parseType(): Type = {
        val left = if(ahead().text == "(") {
            skip("(")
            val t = parseType()
            skip(")")
            t
        } else {
            val nameToken = skipLexeme(LUpper)
            val number = nameToken.text.headOption.exists(_.isDigit)
            var names = if(number && ahead().text == "." && aheadAhead().text == ".") {
                skip(".")
                skip(".")
                val toToken = skipLexeme(LUpper)
                val from = nameToken.text.toInt
                val to = toToken.text.toInt
                List(from.to(to).map(n => TSymbol(toToken.line, n.toString)).reduce[Type](TUnion(toToken.line, _, _)))
            } else List(TSymbol(nameToken.line, nameToken.text))
            while(ahead().lexeme == LUpper) {
                val nameToken2 = skipLexeme(LUpper)
                names ::= TSymbol(nameToken2.line, nameToken2.text)
            }
            names.reverse.reduce(TIntersection(nameToken.line, _, _))
        }
        if(ahead().text == "|") {
            val unionToken = skip("|")
            TUnion(unionToken.line, left, parseType())
        }
        else left
    }

    def parseValue(): Value = {
        val nameToken = skipLexeme(LUpper)
        var properties = List[PropertyValue]()
        while(ahead().lexeme == LUpper) {
            val propertyNameToken = skipLexeme(LUpper)
            skip("(")
            properties ::= PropertyValue(propertyNameToken.line, propertyNameToken.text, parseValue())
            skip(")")
        }
        Value(nameToken.line, nameToken.text, properties.reverse)
    }

    def parseExpression(): Expression = {
        var expressions = List(parseExpressionLine())
        if(ahead().text == ".") {
            while(ahead().text == ".") {
                skip(".")
                val c = ahead().text
                if(c != ")" && c != ";" && c != "|" && c != "[" && ahead().lexeme != LEnd) {
                    expressions ::= parseExpressionLine()
                }
            }
            EMatrix(expressions.head.head.line, KUnknown, expressions.reverse)
        } else {
            expressions.head.head
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
        if(ahead().text == "->") {
            val arrowToken = skip("->")
            val thenBody = parseExpression()
            def booleanPattern(boolean: String) = {
                Pattern(arrowToken.line, KUnknown, None, List(SymbolPattern(arrowToken.line, boolean, None)))
            }
            val thenCase = MatchCase(arrowToken.line, booleanPattern("1"), thenBody)
            val cases = if(ahead().text != "|") List(thenCase) else {
                val elseToken = skip("|")
                val elseBody = parseExpression()
                val elseCase = MatchCase(elseToken.line, booleanPattern("0"), elseBody)
                List(thenCase, elseCase)
            }
            EMatch(arrowToken.line, KUnknown, left, cases)
        } else if(ahead().text == ":") {
            val colonToken = skip(":")
            val p = parsePattern()
            skip("=>")
            val e = parseExpression()
            var cases = List[MatchCase](MatchCase(colonToken.line, p, e))
            while(ahead().text == ";") {
                val semicolonToken = skip(";")
                val p1 = parsePattern()
                skip("=>")
                val e1 = parseExpression()
                cases ::= MatchCase(semicolonToken.line, p1, e1)
            }
            EMatch(colonToken.line, KUnknown, left, cases.reverse)
        } else left
    }

    def parseBinaryOperator(precedence: Int): Expression = if(precedence > 7) parseUpdate() else {
        var result = parseBinaryOperator(precedence + 1)
        while(getPrecedence(ahead().text).contains(precedence)) {
            val operatorToken = skipLexeme(LOperator)
            val right = parseBinaryOperator(precedence + 1)
            result = ECall(operatorToken.line, KUnknown, operatorToken.text, List(result, right))
        }
        result
    }

    def getPrecedence(operator: String) = operator match {
        case "!" => Some(1)
        case "||" => Some(2)
        case "&&" => Some(3)
        case "<>" => Some(4)
        case "<" | ">" | "<=" | ">=" | "==" | "!=" | "===" | "!==" => Some(5)
        case "+" | "-" => Some(6)
        case "*" | "/" | "%" => Some(7)
        case _ => None
    }

    def parseUpdate(): Expression = {
        var result = parseAtom()
        while(ahead().lexeme == LUpper) {
            val propertyToken = skipLexeme(LUpper)
            skip("(")
            val e = parseExpression()
            skip(")")
            result = EProperty(propertyToken.line, KUnknown, result, propertyToken.text, e)
        }
        result
    }

    def parseAtom(): Expression = {
        if(ahead().text == "(") {
            skip("(")
            val e = parseExpression()
            skip(")")
            e
        } else if(ahead().lexeme == LLower && aheadAhead().text == "=") {
            val nameToken = skipLexeme(LLower)
            skip("=")
            val value = parseMatch()
            skip(".")
            val body = parseExpression()
            EMatch(nameToken.line, KUnknown, value, List(MatchCase(nameToken.line,
                Pattern(nameToken.line, KUnknown, Some(nameToken.text), List()),
            body)))
        } else if(ahead().lexeme == LLower && aheadAhead().text == "(") {
            val nameToken = skipLexeme(LLower)
            skip("(")
            var arguments = List[Expression]()
            while(ahead().text != ")") {
                if(arguments.nonEmpty) skip(",")
                arguments ::= parseMatch()
            }
            skip(")")
            ECall(nameToken.line, KUnknown, nameToken.text, arguments.reverse)
        } else if(ahead().text == "!" || ahead().text == "-") {
            val operatorToken = skipLexeme(LOperator)
            val e = parseUpdate()
            ECall(operatorToken.line, KUnknown, operatorToken.text, List(e))
        } else if(ahead().lexeme == LLower) {
            val nameToken = skipLexeme(LLower)
            EVariable(nameToken.line, KUnknown, nameToken.text)
        } else if(ahead().lexeme == LUpper) {
            val nameToken = skipLexeme(LUpper)
            EMaterial(nameToken.line, KUnknown, nameToken.text)
        } else {
            fail(ahead().line, "Expected atomic expression, got " + ahead().lexeme + ": " + ahead().text)
        }
    }

    def parsePatternMatrix(): List[List[Pattern]] = {
        var patterns = List(parsePatternLine())
        while(ahead().text == ".") {
            skip(".")
            if(ahead().text != "--") patterns ::= parsePatternLine()
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
        val token = ahead()
        val name: Option[String] = if(token.lexeme == LLower) {
            val nameToken = skipLexeme(LLower)
            Some(nameToken.text)
        } else if(token.lexeme == LWildcard) {
            skipLexeme(LWildcard)
            None
        } else if(token.lexeme == LUpper) {
            None
        } else {
            fail(ahead().line, "Expected pattern, got " + ahead().lexeme + ": " + ahead().text)
        }
        var properties = List[SymbolPattern]()
        while(ahead().lexeme == LUpper) {
            val nameToken = skipLexeme(LUpper)
            val pattern = if(ahead().text == "(") {
                skip("(")
                val p = parsePattern()
                skip(")")
                Some(p)
            } else None
            properties ::= SymbolPattern(nameToken.line, nameToken.text, pattern)
        }
        Pattern(token.line, KUnknown, name, properties)
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
            throw CompileError(message, line)
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
            else if(m.group(7) != null) Token(m.group(1), LOperator, line)
            else throw CompileError("Unexpected token text: " + m.group(0), line)
        }.filter(_ != null).toArray
    }

    //def main(args : Array[String]) : Unit = {
    //    println(new Parser(code).parseDefinitions())
    //}

}
