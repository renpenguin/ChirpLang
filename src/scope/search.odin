package scope

import p "../parser"
import "core:fmt"

ScopeItem :: union {
	Module,
	Function,
	^Variable,
}

find_module :: proc(scope: ^Scope, query: p.NameDefinition) -> (found_scope: ^Scope, ok: bool) {
	for &module in scope.modules {
		if module.name == query {
			return module.scope, true
		}
	}

	if scope.parent_scope == nil do return
	return find_module(scope.parent_scope, query)
}

find_scope_at_path :: proc(
	scope: ^Scope,
	path: []p.NameDefinition,
) -> (
	found_scope: ^Scope,
	err := ScopeError{ok = true},
) {
	if len(path) == 0 do panic("Empty non-nil path in NameDefinition")

	found_scope = scope

	path_reader: for dir in path {
		ok: bool
		if found_scope, ok = find_module(found_scope, dir); ok {
			continue path_reader
		}

		return nil, ScopeError{err_source = path, type = .InvalidPath}
	}

	return
}

search_scope :: proc(scope: ^Scope, query: p.NameDefinition) -> ScopeItem {
	for &constant in scope.constants {
		if constant.name == query do return &constant
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

search_for_reference :: proc(
	scope: ^Scope,
	query: p.NameReference,
) -> (
	found_item: ScopeItem,
	err := ScopeError{ok = true},
) {
	name_ref_scope := scope
	if path, ok := query.path.?; ok {
		name_ref_scope, err = find_scope_at_path(scope, path[:])
		if !err.ok do return
	}

	found_item = search_scope(name_ref_scope, query.name)
	if found_item == nil do err = ScopeError{err_source = query.name, type = .NotFoundAtPath}

	return
}
