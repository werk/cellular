package cellular.language

object Checker {

    case class CheckerContext(
        materialProperties: Map[String, List[String]],
    )

    def createContext(definitions: List[Definition]) = {
        val valueProperties = definitions.collect { case d : DProperty => d.name }.toSet
        val materialProperties = definitions.collect { case material : DMaterial =>
            material.name -> material.properties.filter(_.value.isEmpty).map(_.property).filter(valueProperties)
        }
        CheckerContext(
            materialProperties = materialProperties.toMap,
        )
    }

    def checkExpression(context: CheckerContext, expression: Expression): Unit = {
        checkMaterialInitialization(context, expression, List())
    }

    def checkMaterialInitialization(
        context: CheckerContext,
        expression: Expression,
        properties: List[(Int, String)]
    ): Unit = expression match {
        case EVariable(line, kind, name) =>
        case EMatch(line, kind, expression, matchCases) =>
            checkMaterialInitialization(context, expression, List())
            matchCases.map(_.body).foreach(checkMaterialInitialization(context, _, List()))
        case ECall(line, kind, function, arguments) =>
            arguments.foreach(checkMaterialInitialization(context, _, List()))
        case EProperty(line, _, expression, property, value) =>
            checkMaterialInitialization(context, expression, (line, property) :: properties)
            checkMaterialInitialization(context, value, List())
        case EMaterial(line, _, material) if material.head.isDigit =>
            if(properties.nonEmpty) {
                fail(properties.head._1, "Number can't have property: " + properties.head._2)
            }
        case EMaterial(line, _, material) =>
            context.materialProperties.get(material) match {
                case None =>
                    fail(line, "No such material: " + material)
                case Some(expected) =>
                    expected.foreach { property =>
                        if(!properties.reverse.exists(_._2 == property)) {
                            fail(line, "Material " + material + " is missing a value for: " + property)
                        }
                    }
                    properties.reverse.foreach { case (line, property) =>
                        if(!expected.contains(property)) {
                            fail(line, "Material " + material + " can't have this property: " + property)
                        }
                    }
            }
        case EMatrix(line, kind, expressions) =>
            expressions.foreach(_.foreach(checkMaterialInitialization(context, _, List())))
    }

    protected def fail(line: Int, message: String) = {
        throw new RuntimeException(message + " at line " + line)
    }

}

