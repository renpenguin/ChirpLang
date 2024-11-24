package scope

import p "../parser"
import "core:fmt"

// Make sure all involved blocks' instructions are only accessing values they have access to
evaluate_block_with_scope :: proc(block: p.Block, scope: Scope) -> (err: ScopeError = nil) {
	using p

	scope := scope
	for instruction in block {
		switch _ in instruction {
		case ImportStatement, FunctionDefinition:
			// Ignore this
			break
		case VariableDefinition:
			var_def := instruction.(p.VariableDefinition)

			err = evaluate_expression_with_scope(var_def.expr, scope)
			if err != nil do return

			append(&scope.constants, Variable{var_def.name, p.None})
		case VariableAssignment:
			var_ass := instruction.(VariableAssignment)

			err = evaluate_name_ref_with_scope(var_ass.target, .Variable, scope)
			if err != nil do return

			err = evaluate_expression_with_scope(var_ass.expr, scope)
			if err != nil do return
		case Forever:
			err = evaluate_block_with_scope(instruction.(Forever).block, scope)
			if err != nil do return
		case Expression:
			err = evaluate_expression_with_scope(instruction.(Expression), scope)
			if err != nil do return
		case p.Expression:
			err = evaluate_expression_with_scope(instruction.(p.Expression), scope)
			if err != nil do return
		}
	}
	return
}

// Make sure the expression's elements are only accessing values they have access to
@(private = "file")
evaluate_expression_with_scope :: proc(
	expr: p.Expression,
	scope: Scope,
) -> (
	err: ScopeError = nil,
) {
	switch _ in expr {
	case p.FunctionCall:
		func_call := expr.(p.FunctionCall)

		err = evaluate_name_ref_with_scope(func_call.name, .Function, scope)
		if err != nil do return

		for arg in func_call.args {
			err = evaluate_expression_with_scope(arg, scope)
			if err != nil do return
		}
	case p.Operation:
		op := expr.(p.Operation)

		err = evaluate_expression_with_scope(op.left^, scope)
		if err != nil do return
		err = evaluate_expression_with_scope(op.right^, scope)
		if err != nil do return
	case p.FormatString:
		panic("todo") // TODO: parse FormatString expressions
	case p.NameReference:
		err = evaluate_name_ref_with_scope(expr.(p.NameReference), .Variable, scope)
		if err != nil do return

	case p.Value:
		break // Do nothing
	}
	return
}

@(private = "file")
evaluate_name_ref_with_scope :: proc(name_ref: p.NameReference, type: enum {
		Module,
		Function,
		Variable,
	}, scope: Scope) -> (err: ScopeError = nil) {
	scope := scope // TODO: `search_for_reference` maybe shouldnt take a reference to the scope? but it's also required for

	found_item: ScopeItem
	found_item, err = search_for_reference(&scope, name_ref)
	if err != nil do return ScopeError(name_ref.name)

	switch type { 	// TODO: make this able to handle passing function references
	case .Module:
		if _, ok := found_item.(Module); !ok do return ScopeError(name_ref.name)
	case .Function:
		if _, ok := found_item.(Function); !ok do return ScopeError(name_ref.name)
	case .Variable:
		if _, ok := found_item.(^Variable); !ok do return ScopeError(name_ref.name)
	}

	return
}
