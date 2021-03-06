package cellular.language

import cellular.language.Language.Expression

object Expressions {

    def translate(expression : Expression, parenthesis : Boolean) : String = {
        def enclose(code : String) : String = if(parenthesis) "(" + code + ")" else code
        def go(expression : Expression) = translate(expression, parenthesis = true)
        expression match {
            case Language.EUnary("!", Language.EIsDefined(e)) =>
                go(e) + " == NOT_FOUND"
            case Language.EIsDefined(e) =>
                go(e) + " != NOT_FOUND"
            case Language.EUnary("!", Language.EIs(left, kind)) =>
                go(left) + ".material != " + kind
            case Language.EIs(left, kind) =>
                // const uint not_found = 4294967295;
                // #define is_heat(x) (get_heat(x) != not_found)
                //"is_" + kind + "(" + go(left) + ")"
                go(left) + ".material == " + kind
            case Language.EField(left, kind) =>
                //"get_" + kind + "(" + go(left) + ")"
                go(left) + "." + kind
            case Language.EDid(name) => "did_" + name
            case Language.EPeek(x, y) => Usages.peek(x, y)
            case Language.EBool(value) => value.toString
            case Language.ENumber(value) => value.toString
            case Language.EVariable(name) => escape(name)
            case Language.EBinary(o, left, right) => enclose(go(left) + operator(o) + go(right))
            case Language.EUnary(o, condition) => o + go(condition)
            case Language.EIf(condition, thenBody, elseBody) =>
                enclose(go(condition) + " ? " + go(thenBody) + " : " + go(elseBody))
            case Language.EApply(name, arguments) =>
                name + "(" + arguments.map(go).mkString(", ") + ")"
        }
    }

    def negate(expression : Expression) : Expression = expression match {
        case Language.EBool(value) => Language.EBool(!value)
        case Language.EBinary("=", left, right) => Language.EBinary("<>", left, right)
        case Language.EBinary("<>", left, right) => Language.EBinary("=", left, right)
        case Language.EBinary("<=", left, right) => Language.EBinary(">", left, right)
        case Language.EBinary("<", left, right) => Language.EBinary(">=", left, right)
        case Language.EBinary(">=", left, right) => Language.EBinary("<", left, right)
        case Language.EBinary(">", left, right) => Language.EBinary("<=", left, right)
        case Language.EBinary("&", left, right) => Language.EBinary("|", negate(left), negate(right))
        case Language.EBinary("|", left, right) => Language.EBinary("&", negate(left), negate(right))
        case Language.EUnary("!", condition) => condition
        case _ => Language.EUnary("!", expression)
    }

    def operator(name : String) : String = " " + {
        if(name == "=") "=="
        else if(name == "<>") "!="
        else if(name == "&") "&&"
        else if(name == "|") "||"
        else name
    } + " "

    def escape(name : String) : String = {
        if(reserved(name)) name + "_" else name
    }

    // https://stackoverflow.com/questions/6232153/what-keywords-glsl-introduce-to-c
    val reserved = Set("""
auto if break int case long char register
continue return default short do sizeof
double static else struct entry switch extern
typedef float union for unsigned
goto while enum void const signed volatile
attribute uniform varying layout centroid flat
smooth noperspective patch sample subroutine in
out inout invariant discard mat2 mat3 mat4 dmat2
dmat3 dmat4 mat2x2 mat2x3 mat2x4 dmat2x2 dmat2x3
dmat2x4 mat3x2 mat3x3 mat3x4 dmat3x2 dmat3x3 dmat3x4
mat4x2 mat4x3 mat4x4 dmat4x2 dmat4x3 dmat4x4 vec2
vec3 vec4 ivec2 ivec3 ivec4 bvec2 bvec3 bvec4 dvec2
dvec3 dvec4 uvec2 uvec3 uvec4 lowp mediump highp
precision sampler1D sampler2D sampler3D samplerCube
sampler1DShadow sampler2DShadow samplerCubeShadow
sampler1DArray sampler2DArray sampler1DArrayShadow
sampler2DArrayShadow isampler1D isampler2D isampler3D
isamplerCube isampler1DArray isampler2DArray usampler1D
usampler2D usampler3D usamplerCube usampler1DArray
usampler2DArray sampler2DRect sampler2DRectShadow
isampler2DRect usampler2DRect samplerBuffer isamplerBuffer
usamplerBuffer sampler2DMS isampler2DMS usampler2DMS
sampler2DMSArray isampler2DMSArray usampler2DMSArray
samplerCubeArray samplerCubeArrayShadow isamplerCubeArray
usamplerCubeArray
common partition active asm class union enum typedef
template this packed goto inline noinline volatile public
static extern external interface long short half fixed
unsigned superp input output hvec2 hvec3 hvec4 fvec2 fvec3
fvec4 sampler3DRect filter image1D image2D image3D
imageCube iimage1D iimage2D iimage3D iimageCube uimage1D
uimage2D uimage3D uimageCube image1DArray image2DArray
iimage1DArray iimage2DArray uimage1DArray uimage2DArray
image1DShadow image2DShadow image1DArrayShadow
image2DArrayShadow imageBuffer iimageBuffer uimageBuffer
sizeof cast namespace using row_major
    """.split(' ').map(_.trim).filter(_.nonEmpty) : _*)

}
