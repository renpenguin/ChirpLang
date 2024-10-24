package scope

import p "../parser"
import t "../tokeniser"
import "core:fmt"

Module :: struct {
	name:  p.NameDefinition,
	scope: Scope,
}

Variable :: struct {
	name:     p.NameDefinition,
	// Variable can be of type int, float, string or bool
	contents: p.Value,
}

Scope :: struct {
	parent_scope: ^Scope,
	modules:      [dynamic]Module,
	functions:    [dynamic]Function,
	constants:    [dynamic]Variable,
}

ScopeError :: struct {
	error_msg: string,
	ok:        bool,
}

// Builds a `Scope` value for the block and any nested functions or libraries. This will remove all `FunctionDefinition`s and `ImportStatement`s from the block
build_scope :: proc(
	block: ^p.Block,
	parent_module: ^Scope,
) -> (
	scope: Scope,
	err := ScopeError{ok = true},
) {
	scope.parent_scope = parent_module

	for instruction, i in block {
		if import_statement, ok := instruction.(p.ImportStatement); ok {
			// These do nothing for now
		}

		if func_declaration, ok := instruction.(p.FunctionDefinition); ok {
			append(&scope.functions, InterpretedFunction{func_declaration, &scope})
		}

		// Evaluate constants (for math:constants:pi)
	}

	return
}
