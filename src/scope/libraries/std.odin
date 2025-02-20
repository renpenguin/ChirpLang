package libraries

import p "../../parser"
import t "../../tokeniser"
import d "../definitions"
import "core:fmt"

@(private = "file")
std_print :: proc(args: [dynamic]p.Value) -> (return_value := p.None, err := FuncError{ok = true}) {
	for arg in args {
		fmt.printf("%v ", arg)
	}
	fmt.println()

	return
}

// Generate the standard library
build_std_scope :: proc() -> (std: ^d.Scope) {
	using p

	std = new(d.Scope)
	append(&std.functions, d.BuiltInFunction{NameDefinition("print"), std_print})

	return
}
