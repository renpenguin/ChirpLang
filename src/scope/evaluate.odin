package scope

import p "../parser"
import "core:fmt"

// Make sure all involved blocks' instructions are only accessing values they have access to
evaluate_block_with_scope :: proc(block: p.Block, scope: ^Scope) -> (err := ScopeError{ok = true}) {
	using p

	for instruction in block {
		switch inst in instruction {
		case ImportStatement, FunctionDefinition, LoopControl:
			// Ignore this
			break
		case VariableDefinition:
			err = evaluate_expression_with_scope(inst.expr, scope)
			if !err.ok do return

			append(&scope.constants, Variable{inst.name, p.None, inst.mutable})
		case VariableAssignment:
			err = evaluate_name_ref_with_scope(inst.target, .Variable, scope^)
			if !err.ok do return

			found, _ := search_for_reference(scope, inst.target)

			if !found.(^Variable).mutable do return ScopeError{err_source = inst.target.name, type = .ModifiedImmutable}

			err = evaluate_expression_with_scope(inst.expr, scope)
			if !err.ok do return
		case While:
			err = evaluate_expression_with_scope(inst.condition, scope)
			if !err.ok do return
			err = evaluate_block_with_scope(inst.block, scope)
			if !err.ok do return
		case IfStatement:
			err = evaluate_if_statement_with_scope(inst, scope)
			if !err.ok do return
		case Expression:
			err = evaluate_expression_with_scope(inst, scope)
			if !err.ok do return
		case Return:
			err = evaluate_expression_with_scope(Expression(inst), scope)
			if !err.ok do return
		}
	}
	return
}

// Make sure an if statement is only accessing values it has access to
@(private = "file")
evaluate_if_statement_with_scope :: proc(
	if_statement: p.IfStatement,
	scope: ^Scope,
) -> (
	err := ScopeError{ok = true},
) {
	err = evaluate_expression_with_scope(if_statement.condition, scope)
	if !err.ok do return

	err = evaluate_block_with_scope(if_statement.true_block, scope)
	if !err.ok do return

	switch branch in if_statement.else_branch {
	case ^p.IfStatement:
		return evaluate_if_statement_with_scope(branch^, scope)
	case p.Block:
		return evaluate_block_with_scope(branch, scope)
	case:
		return
	}
}

// Make sure the expression's elements are only accessing values they have access to
@(private = "file")
evaluate_expression_with_scope :: proc(expression: p.Expression, scope: ^Scope) -> (err := ScopeError{ok = true}) {
	switch expr in expression {
	case p.FunctionCall:
		err = evaluate_name_ref_with_scope(expr.name, .Function, scope^)
		if !err.ok do return

		for arg in expr.args { // TODO: evaluate that expressions fit func args
			err = evaluate_expression_with_scope(arg, scope)
			if !err.ok do return
		}
	case p.Operation:
		err = evaluate_expression_with_scope(expr.left^, scope)
		if !err.ok do return
		err = evaluate_expression_with_scope(expr.right^, scope)
		if !err.ok do return
	case p.FormatString:
		for arg in expr {
			err = evaluate_expression_with_scope(arg, scope)
			if !err.ok do return
		}
	case p.NameReference:
		err = evaluate_name_ref_with_scope(expr, .Variable, scope^)
		if !err.ok do return

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
	}, scope: Scope) -> (err: ScopeError) {
	scope := scope // TODO: `search_for_reference` maybe shouldnt take a reference to the scope? but it's also required for

	found_item: ScopeItem
	found_item, err = search_for_reference(&scope, name_ref)
	if !err.ok do return

	err = ScopeError{name_ref.name, .NotFoundAtPath, true}
	switch type { 	// TODO: make this able to handle passing function references
	case .Module:
		if _, ok := found_item.(Module); !ok do err.ok = false
	case .Function:
		if _, ok := found_item.(Function); !ok do err.ok = false
	case .Variable:
		if _, ok := found_item.(^Variable); !ok do err.ok = false
	}

	return
}
