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

ScopeError :: union {
	[]p.NameDefinition,
	p.NameDefinition,
}

// Builds a `Scope` value for the block and any nested functions or libraries. This will remove all `FunctionDefinition`s and `ImportStatement`s from the block
build_scope :: proc(
	block: ^p.Block,
	parent_module: ^Scope,
) -> (
	scope: Scope,
	err: ScopeError = nil,
) {
	scope.parent_scope = parent_module

	for instruction, i in block {
		if import_statement, ok := instruction.(p.ImportStatement); ok {
			// These do nothing for now
		}

		if func_declaration, ok := instruction.(p.FunctionDefinition); ok {
			function_scope := Scope {
				parent_scope = &scope,
			}
			defer destroy_scope(function_scope)
			
			for arg in func_declaration.args {
				append(&function_scope.constants, Variable{arg.name, p.None})
			}
			err = evaluate_block_with_scope(func_declaration.block, function_scope)
			if err != nil do return

			append(&scope.functions, InterpretedFunction(func_declaration))
		}

		// Evaluate constants (for math:constants:pi)
	}

	return scope, evaluate_block_with_scope(block^, scope)
}

// Recursively destroy everything stored in the scope
destroy_scope :: proc(scope: Scope) {
	for mod in scope.modules {
		destroy_scope(mod.scope)
	}
	delete(scope.modules)
	delete(scope.constants)
	delete(scope.functions)
}
