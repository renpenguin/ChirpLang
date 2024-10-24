package scope

import p "../parser"
import "core:fmt"

@(private = "file")
std_print :: proc(
	args: [dynamic]p.Value,
) -> (
	return_value: Maybe(p.Value),
	err := FunctionError{ok = true},
) {
	for arg in args {
		fmt.printf("%v ", arg)
	}
	fmt.println()

	return
}

import "core:math/rand"
@(private = "file")
std_random_range :: proc(
	args: [dynamic]p.Value,
) -> (
	return_value: Maybe(p.Value),
	err := FunctionError{ok = true},
) {
	if len(args) != 2 do return nil, FunctionError{msg = "Incorrect number of args"}
	min, max: int
	min, err.ok = args[0].(int)
	if !err.ok {err.msg = "min value must be int";return}
	max, err.ok = args[1].(int)
	if !err.ok {err.msg = "max value must be int";return}

	if min > max do return nil, FunctionError{msg = "Max must be greater than min"}

	return rand.int_max(max - min) + min, err
}

// Generate the standard library
build_std_scope :: proc() -> (std: Scope) {
	using p

	append(&std.functions, BuiltInFunction{NameDefinition("print"), std_print})

	std_random := Module{NameDefinition("random"), Scope{}}
	append(&std_random.scope.functions, BuiltInFunction{NameDefinition("range"), std_random_range})
	append(&std.modules, std_random)

	return
}
