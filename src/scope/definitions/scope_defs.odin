package scope_defs

import p "../../parser"

Scope :: struct {
	parent_scope: ^Scope,
	modules:      [dynamic]Module,
	functions:    [dynamic]Function,
	constants:    [dynamic]Variable,
}

Module :: struct {
	name:  p.NameDefinition,
	scope: ^Scope,
}

Variable :: struct {
	name:     p.NameDefinition,
	// Variable can be of type int, float, string or bool
	contents: p.Value,
	mutable:  bool,
}
