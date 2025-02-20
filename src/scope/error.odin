package scope

import p "../parser"
import "core:fmt"

ScopeError :: struct {
	err_source: union #no_nil {
		[]p.NameDefinition,
		p.NameDefinition,
		Module,
	},
	type:       enum {
		Redefinition,
		ModifiedImmutable,
		ModuleNotFound,
		InvalidPath,
		NotFoundAtPath,
	},
	ok:         bool,
}

// Display an appropriate error message for the passed error, and returns true if an error was found and printed
display_scope_error :: proc(err: ScopeError) -> bool {
	if !err.ok {
		switch err.type {
		case .Redefinition:
			if _, ok := err.err_source.(Module); ok {
				fmt.eprintln("Scope error: attempt to import module that already exists:", err.err_source)
			} else {
				fmt.eprintln("Scope error: redefinition of function", err.err_source)
			}
		case .ModifiedImmutable:
			fmt.eprintln("Scope error: attempted to modify immutable variable:", err.err_source)
		case .ModuleNotFound:
			fmt.eprintln("Scope error: couldn't find module:", err.err_source)
		case .InvalidPath:
			fmt.eprintln("Scope error: invalid path:", err.err_source)
		case .NotFoundAtPath:
			fmt.eprintln("Scope error: couldn't find name at path:", err.err_source)
		}
	}
	return !err.ok
}
