package libraries

import "core:math/rand"
import d "../definitions"
import p "../../parser"
import t "../../tokeniser"

@(private = "file")
mod_random_range :: proc(
	args: [dynamic]p.Value,
) -> (
	return_value: p.Value,
	err := FuncError{ok = true},
) {
	if len(args) != 2 do return p.None, FuncError{msg = "Incorrect number of args"}
	min, max: int
	min, err.ok = args[0].(int)
	if !err.ok {err.msg = "min value must be int";return}
	max, err.ok = args[1].(int)
	if !err.ok {err.msg = "max value must be int";return}

	if min > max do return p.None, FuncError{msg = "Max must be greater than min"}

	return rand.int_max(max - min) + min, err
}

@private
mod_random :: proc() -> d.Module {
	using p, d
	mod := Module{NameDefinition("random"), Scope{}}
	append(&mod.scope.functions, BuiltInFunction{NameDefinition("range"), mod_random_range})

	return mod
}