package scope

import "core:fmt"
import p "../parser"

find_module :: proc(scope: ^Scope, query: p.NameDefinition) -> (found_scope: Scope, ok: bool) {
	for module in scope.modules {
		if module.name == query {
			return module.scope, true
		}
	}

	if scope.parent_scope == nil do return
	return find_module(scope.parent_scope, query)
}

find_scope_at_path :: proc(
	scope: Scope,
	path: []p.NameDefinition,
) -> (
	found_scope: Scope,
	err: ScopeError = nil,
) {
	if len(path) == 0 do panic("Empty non-nil path in NameDefinition")

	found_scope = scope

	path_reader: for dir in path {
		ok: bool
		if found_scope, ok = find_module(&found_scope, dir); ok {
			continue path_reader
		}

		err = ScopeError(path)
		return
	}

	return
}

search_scope :: proc(scope: ^Scope, query: p.NameDefinition) -> union {
		Module,
		Function,
		Variable,
	} {
	for constant in scope.constants {
		if constant.name == query do return constant
	}
	for function in scope.functions {
		if get_function_name(function) == query do return function
	}
	for module in scope.modules {
		if module.name == query do return module
	}

	if scope.parent_scope == nil do return nil
	return search_scope(scope.parent_scope, query)
}
