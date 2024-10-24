package scope

import "core:fmt"
import p "../parser"

// Make sure all involved blocks' instructions are only accessing values they have access to
evaluate_block_with_scope :: proc(block: p.Block, scope: Scope) -> (err := ScopeError{ok = true}) {
	scope := scope
	for instruction in block {
		switch _ in instruction {
		case p.ImportStatement, p.FunctionDefinition: // Ignore this
		case p.VariableDefinition:
			var_def := instruction.(p.VariableDefinition)

			err = evaluate_expression_with_scope(var_def.expr, scope)
			if !err.ok do return

			append(&scope.constants, Variable{var_def.name, p.None})
		case p.VariableAssignment:
			var_ass := instruction.(p.VariableAssignment)

			err = evaluate_name_ref_with_scope(var_ass.target, scope)
			if !err.ok do return

			err = evaluate_expression_with_scope(var_ass.expr, scope)
			if !err.ok do return
		case p.Forever:
			err = evaluate_block_with_scope(instruction.(p.Forever).block, scope)
			if !err.ok do return
		case p.Expression:
			err = evaluate_expression_with_scope(instruction.(p.Expression), scope)
			if !err.ok do return
		}
	}
	return
}

// Make sure the expression's elements are only accessing values they have access to
@(private="file")
evaluate_expression_with_scope :: proc(
	expr: p.Expression,
	scope: Scope,
) -> (
	err := ScopeError{ok = true},
) {
	#partial switch _ in expr {
	case p.FunctionCall:
		func_call := expr.(p.FunctionCall)

		err = evaluate_name_ref_with_scope(func_call.name, scope)
		if !err.ok do return

		for arg in func_call.args {
			err = evaluate_expression_with_scope(arg, scope)
			if !err.ok do return
		}
	case p.Operation:
		op := expr.(p.Operation)

		err = evaluate_expression_with_scope(op.left^, scope)
		err = evaluate_expression_with_scope(op.right^, scope)
	case p.NameReference:
		fmt.println("evaluating name ref", expr.(p.NameReference))
		err = evaluate_name_ref_with_scope(expr.(p.NameReference), scope)
		if !err.ok do return
	}
	return
}

@(private="file")
evaluate_name_ref_with_scope :: proc(
	name_ref: p.NameReference,
	scope: Scope,
) -> (
	err := ScopeError{ok = true},
) {
	name_ref_scope := scope
	if path, ok := name_ref.path.?; ok {
		name_ref_scope, err = find_scope_at_path(scope, path[:])
		if !err.ok do return
	}

	found_item := search_scope(&name_ref_scope, name_ref.name)
	if found_item == nil do return ScopeError{error_msg = "Couldn't find name at path"}

	return
}
