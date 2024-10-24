package scope

import "core:fmt"
import p "../parser"

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
		for module in scope.modules {
			if module.name == dir {
				found_scope = module.scope
				continue path_reader
			}
		}
		for module in scope.parent_scope.modules {
			if module.name == dir {
				found_scope = module.scope
				continue path_reader
			}
		}

		err = ScopeError(path)
		return
	}

	return
}

search_scope :: proc(scope: ^Scope, query: p.NameDefinition, path_depth := 0) -> union {
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
