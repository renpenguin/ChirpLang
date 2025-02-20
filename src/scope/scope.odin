package scope

import p "../parser"
import t "../tokeniser"
import d "./definitions"
import l "./libraries"
import "core:fmt"

Module :: d.Module
Variable :: d.Variable
Scope :: d.Scope

// Builds a `Scope` value for the block and any nested functions or libraries. This will remove all `FunctionDefinition`s and `ImportStatement`s from the block
build_scope :: proc(block: ^p.Block, parent_module: ^Scope) -> (scope: ^Scope, err := ScopeError{ok = true}) {
	scope = new(Scope)
	scope.parent_scope = parent_module

	for instruction in block {
		if import_statement, ok := instruction.(p.ImportStatement); ok {
			for name_ref in import_statement {
				module, ok := l.try_access_library(name_ref)
				if !ok do return scope, ScopeError{err_source = name_ref.name, type = .ModuleNotFound}

				if _, mod_already_exists := find_module(scope, module.name); mod_already_exists {
					return scope, ScopeError{err_source = module, type = .Redefinition}
				}

				append(&scope.modules, module)
			}
		}

		if func_declaration, ok := instruction.(p.FunctionDefinition); ok {
			if search_scope(scope, func_declaration.name) != nil {
				return scope, ScopeError{err_source = func_declaration.name, type = .Redefinition}
			}

			append(&scope.functions, InterpretedFunction{func_declaration, scope})
		}

		// Evaluate constants (for math:constants:pi)
	}

	err = evaluate_block_with_scope(block^, scope)
	if !err.ok do return

	for func in scope.functions {
		if interp_func, ok := func.(d.InterpretedFunction); ok {
			func_scope := new(Scope)
			defer destroy_scope(func_scope)
			func_scope.parent_scope = interp_func.parent_scope

			for arg in interp_func.args { 	// TODO: check arg types/count against passed args
				append(&func_scope.constants, Variable{arg.name, p.None, false})
			}

			err = evaluate_block_with_scope(interp_func.block, func_scope)
			if !err.ok do return
		}
	}

	return
}

// Recursively destroy everything stored in the scope
destroy_scope :: proc(scope: ^Scope) {
	for mod in scope.modules {
		destroy_scope(mod.scope)
	}
	delete(scope.modules)
	delete(scope.constants)
	delete(scope.functions)
	free(scope)
}
