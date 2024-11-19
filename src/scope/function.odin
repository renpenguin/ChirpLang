package scope

import p "../parser"

// Defines a function. Expected pattern `func $name$($name$, ...) $block$`
InterpretedFunction :: struct {
	using func: p.FunctionDefinition,
	scope:      ^Scope,
}

// Error returned by external functions in case of an error with the input values
BuiltInFunctionError :: struct {
	msg: string,
	ok:        bool,
}

@private
FunctionError :: BuiltInFunctionError

// Holds a pointer to an Odin function
BuiltInFunction :: struct {
	name:     p.NameDefinition,
	func_ref: #type proc(
		args: [dynamic]p.Value,
	) -> (
		return_value: p.Value,
		err: FunctionError,
	),
}

Function :: union {
	InterpretedFunction, // User-written function
	BuiltInFunction,
}

// Gets the function name, regardless of the union type
get_function_name :: proc(func: Function) -> p.NameDefinition {
	switch _ in func {
	case InterpretedFunction:
		return func.(InterpretedFunction).name
	case BuiltInFunction:
		return func.(BuiltInFunction).name
	case:
		panic("Unreachable")
	}
}
