package cellular.mini

object Codec {

    def sizeOf(context: TypeContext, fixed: FixedType): Int = {
        val materialNames = materialsOf(context, fixed.valueType).toList
        materialNames.map(materialSizeOf(context, _, fixed.fixed)).sum
    }

    def materialSizeOf(context: TypeContext, materialName: String, fixed: List[PropertyValue] = List()): Int = {
        if(materialName.head.isDigit) return 1
        val properties = context.materials.getOrElse(materialName, {
            throw new RuntimeException("No such material: " + materialName)
        })
        properties.filter(_.property != materialName).map {
            case MaterialProperty(_, _, Some(_)) => 1
            case MaterialProperty(_, propertyName, None) if fixed.exists(_.property == propertyName) => 1
            case MaterialProperty(_, propertyName, None) => propertySizeOf(context, propertyName)
        }.product
    }

    def propertySizeOf(context: TypeContext, propertyName: String): Int = {
        if(propertyName.head.isDigit) 1 else
        context.properties.get(propertyName) match {
            case None => throw new RuntimeException("No such property: " + propertyName)
            case Some(fixedType1) => sizeOf(context, fixedType1)
        }
    }

    def materialsOf(context: TypeContext, type0: Type): Set[String] = type0 match {
        case TIntersection(_, type1, type2) =>
            materialsOf(context, type1) intersect materialsOf(context, type2)
        case TUnion(_, type1, type2) =>
            materialsOf(context, type1) union materialsOf(context, type2)
        case TSymbol(_, name) =>
            context.typeAliases.get(name).map(materialsOf(context, _)).getOrElse {
                if(name.head.isDigit || context.materials.contains(name)) Set(name) else
                context.propertyMaterials.get(name) match {
                    case None => throw new RuntimeException("No such property: " + name)
                    case Some(materials) => materials
                }
            }
    }

    def encodeValue(context: TypeContext, fixedType: FixedType, value: Value): Int = {
        if(value.material.head.isDigit) return value.material.toInt
        // TODO: Check that fixedType allows value.materials and all the properties are present?
        var result = 0
        val materials = materialsOf(context, fixedType.valueType).toList.sorted
        for(m <- materials.takeWhile(_ != value.material)) {
            result += materialSizeOf(context, m, fixedType.fixed)
        }
        for(PropertyValue(_, property, value) <- value.properties.sortBy(_.property)) {
            val constant = !value.material.head.isDigit &&
                context.materials(value.material).exists(p => p.property == property && p.value.nonEmpty)
            if(!constant && !fixedType.fixed.exists(_.property == property)) {
                val propertyFixedType = context.properties(property)
                result *= propertySizeOf(context, property)
                result += encodeValue(context, propertyFixedType, value)
            }
        }
        result
    }

    def decodeValue(context: TypeContext, fixedType: FixedType, number: Int): Value = {
        val materials = materialsOf(context, fixedType.valueType).toList.sorted
        if(materials.head.head.isDigit) return Value(0, number.toString, List())
        var remaining = number
        val material = materials.find { m =>
            val size = materialSizeOf(context, m, fixedType.fixed)
            if(remaining < size) true else {
                remaining -= size
                false
            }
        }.get
        val properties = context.materials(material).sortBy(_.property).reverse
        val values = for(property <- properties) yield property.property -> property.value.getOrElse {
            fixedType.fixed.find(_.property == property.property).map(_.value).getOrElse {
                val propertyFixedType = context.properties(property.property)
                val size = propertySizeOf(context, property.property)
                val propertyNumber = remaining % size
                remaining = remaining / size
                decodeValue(context, propertyFixedType, propertyNumber)
            }
        }
        val propertyValues = values.map { case (k, v) => PropertyValue(0, k, v) }
        Value(0, material, propertyValues)
    }

}
