# cellular
A DSL for cellular automata running on the GPU using Margolus neighborhoods 

# Introduction

The primary purpose of the language is to update in parallel all 2x2 areas of a tile map, in a grid that is offset by (0, 0) in even frames and (1, 1) in odd frames.

Tiles are represented as values on the form `M P1(v1) P2(v2) ...` where `M` is a material name, `P1, P2, ...` are property names and `v1, v2, ...` are property values.

The tile values are compactly encoded into 32bit unsigned integers, and stored in a texture.


# Expressions

Expressions in the core language may be one of the following:
* A variable name `X`.
* A material name `M`.
* A property update `e1 P(e2)`, where `e1` and `e2` are expressions, and `P` is a property name.
* A function call `F(e, ...)`, where `F` is a function name and `e, ...` is zero or more expressions.
* A pattern match `e1 : p => e2 ; ...` where `e1` and `e2` are an expressions, `p` is a pattern, and `; ...` is zero or more alternative `p => e` cases.

On top of that, a bit of syntactic sugar: 
* "Let": `X = e1. e2`, where `X` is a variable name and `e1` and `e2` are expressions, is syntactic sugar for `e1 : X => e2`.
* "If": `e1 -> e2 | e3`, where `e1`, `e2`, `e3` are expressions and `| e3` is optional, is syntactic sugar for `e1 : 1 => e2 ; 0 => e3`.

When a pattern match is unexhaustive and encounters a value that no case matches, the rule in which it's evaluated doesn't apply.

The last case is *expression matrices*, as described in the `[rule ...]` section below. They may not occur as the scrutinee of a pattern, as property values, or as arguments to functions or operators. 

Patterns are written `X P(p) ...` where `X` is a variable name, and `P(p) ...` is zero or more `P(p)` where `P` is a type name, property name or material name and `p` is a pattern. The `(p)` part is only allowed after property names, and may be omitted, allowing any value. The variable name may be omitted if there's at least one `P`.


# Programs

A program is a sequence of *sections*, each starting with a *section header* like this:
```[sectiontype ...]```

What goes in `...` depends on the section type.

## `[properties]`

This section lists zero or more *properties*, which are used to attach data to *materials*.

**Example:**
```
[properties]

Weight(0..3)
Temperature(0..3)
Content(Resource) { Temperature?(0) ChestCount?(0) Content?(0) }
ChestCount(0..3)
Foreground(Resource | Imp | Air)
Background(Black | White)
```

* `Weight(0..3)` declares a *numeric* property that can take on the values 0, 1, 2 or 3.
* `Content(Resource) { ... }` declares a *structural* property whose value is any `Resource`. 
`Temperature?(0)` declares that if the attatched resource has a `Temperature`, then it must be `0`.

Note that fixing the value at `0` means that we don't have to store the value in the encoding, since it's known statically.

Union types `t1 | t2` and intersection types `t1 & t2` are supported for structural properties.

## `[materials]`

**Example:**
```
[materials]

Chest { Content ChestCount Resource }
Imp { Content }
Stone { Weight(2) }
IronOre { Temperature }
Water { Temperature Weight(1) }
Air { Weight(0) }
Tile { Foreground Background }
Black
White
```

* `Black` declares a material with no properties.
* `IronOre` declares a material with the properties `Temperature`, where the value of `Temperature` may vary.
* `Stone` declares a material with ther properties `Weight`, where the value of `Weight` is a constant `2`.

## `[types]`

**Example:**
```
[types]

Resource = Stone | IronOre | Water.
```

The above compares a *type alias* named `Resource` that is either `Stone`, `IronOre` or `Water`.

## `[group <name> <scheme>?]`

Rules are grouped into *rule groups*. A `[group ...]` section is followed by zero or more `[rule ...]` sections which belong to that group.

A *scheme* may be provided, which modifies the rule:
* `MyProperty` lets the rule apply only to the contents of a structural property, in this case `MyProperty`. By using this both in the group and the rule, you can nest it.
* `!ruleOrGroupName` skips the rule if `ruleOrGroupName` already applied. It can also be the name of the current rule or group, in which case it can only apply in one way per frame.
* `@90`, `@180`, `@270` also applies the rule rotated that number of degrees counterclockwise.
* `@r` is shortand for all three rotations above.
* `@h`, `@v` also applies the rule flipped horizontally or vertically.

## `[rule <name> <scheme>?]`

A rule consists of a *pattern matrix* and an *expression*, separated from each other by the token `--`.

The matrix is divided into rows, ending in `.` and cells, separated by `,`, e.g.:
```
x, y, z.
p, q, r.
```

**Example:**
```
[rule fall]

a Weight(x).
b Weight(y).
-- x > y ->
b.
a.
```

The above example declares a rule named `fall` whose pattern matrix is 1 column wide and 2 rows high.

Then comes the separator `--`, followed by a conditional `x > y -> ...`. Only if the condition holds does the rule apply.

Then comes an *expression matrix* `b. a.`, in this case of the same dimensions as the pattern matrix.

In summary, this rule says that if we have a tile `a` above a tile `b` and the weight of `a` is greater than the weight of `b`, then swap their positions, so that the heavier tile goes to the bottom.

In general, the value of the expression matrix replaces the center of the area matched by the *pattern matrix*. It's 1 wide if the pattern matrix has an odd width, and 2 wide if the pattern matrix has an even width. The same logic applies to the height.
