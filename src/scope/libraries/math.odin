package libraries

import p "../../parser"
import t "../../tokeniser"
import d "../definitions"
import "core:math"

@(private = "file")
mod_math_sin :: proc(args: [dynamic]p.Value) -> (return_value: p.Value, err := FuncError{ok = true}) {
	if len(args) != 1 do return p.None, FuncError{msg = "Incorrect number of args, expected 1"}

	value, ok := args[0].(t.float)
	if !ok do return p.None, FuncError{msg = "Only argument must be float"}

	return math.sin_f64(value), err
}

@(private)
mod_math :: proc() -> d.Module {
	using p, d
	mod := Module{NameDefinition("math"), new(Scope)}
	append(&mod.scope.functions, BuiltInFunction{NameDefinition("sin"), mod_math_sin})
	std_math_constants := Module{NameDefinition("constants"), new(Scope)}
	append(&std_math_constants.scope.constants, Variable{NameDefinition("pi"), Value(math.PI), false})
	append(&mod.scope.modules, std_math_constants)

	return mod
}
