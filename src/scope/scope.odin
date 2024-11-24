package scope

import p "../parser"
import t "../tokeniser"
import d "./definitions"
import l "./libraries"
import "core:fmt"

Module :: d.Module
Variable :: d.Variable
Scope :: d.Scope

ScopeError :: struct {
	err_source: union #no_nil {
		[]p.NameDefinition,
		p.NameDefinition,
		Module,
	},
	ok:         bool,
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
			for name_ref in import_statement {
				module, ok := l.try_access_library(name_ref)
				if !ok do return scope, ScopeError{err_source = name_ref.name}

				if _, mod_already_exists := find_module(&scope, module.name); mod_already_exists {
					return scope, ScopeError{err_source = module}
				}

				append(&scope.modules, module)
			}
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
			if !err.ok do return

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
