package scope_defs

import p "../../parser"

// Defines a function. Expected pattern `func $name$($name$, ...) $block$`
InterpretedFunction :: struct {
	using func:   p.FunctionDefinition,
	parent_scope: ^Scope,
}

// Error returned by external functions in case of an error with the input values
FunctionError :: struct {
	msg: string,
	func_name: p.NameReference,
	ok:  bool,
}

// Holds a pointer to an Odin function
BuiltInFunction :: struct {
	name:     p.NameDefinition,
	func_ref: #type proc(args: [dynamic]p.Value) -> (return_value: p.Value, err: FunctionError),
}

Function :: union {
	InterpretedFunction, // User-written function
	BuiltInFunction,
}
