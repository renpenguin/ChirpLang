package scope

import p "../parser"
import "core:fmt"

// Make sure all involved blocks' instructions are only accessing values they have access to
evaluate_block_with_scope :: proc(block: p.Block, scope: ^Scope) -> (err := ScopeError{ok = true}) {
	using p

	for instruction in block {
		switch _ in instruction {
		case ImportStatement, FunctionDefinition, LoopControl:
			// Ignore this
			break
		case VariableDefinition:
			var_def := instruction.(p.VariableDefinition)

			err = evaluate_expression_with_scope(var_def.expr, scope)
			if !err.ok do return

			append(&scope.constants, Variable{var_def.name, p.None, var_def.mutable})
		case VariableAssignment:
			var_ass := instruction.(VariableAssignment)

			err = evaluate_name_ref_with_scope(var_ass.target, .Variable, scope^)
			if !err.ok do return

			found, _ := search_for_reference(scope, var_ass.target)

			if !found.(^Variable).mutable do return ScopeError{err_source = var_ass.target.name, type = .ModifiedImmutable}

			err = evaluate_expression_with_scope(var_ass.expr, scope)
			if !err.ok do return
		case While:
			err = evaluate_expression_with_scope(instruction.(p.While).condition, scope)
			if !err.ok do return
			err = evaluate_block_with_scope(instruction.(While).block, scope)
			if !err.ok do return
		case IfStatement:
			err = evaluate_if_statement_with_scope(instruction.(p.IfStatement), scope)
			if !err.ok do return
		case Expression:
			err = evaluate_expression_with_scope(instruction.(Expression), scope)
			if !err.ok do return
		case Return:
			err = evaluate_expression_with_scope(Expression(instruction.(Return)), scope)
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

	switch _ in if_statement.else_branch {
	case ^p.IfStatement:
		return evaluate_if_statement_with_scope(if_statement.else_branch.(^p.IfStatement)^, scope)
	case p.Block:
		return evaluate_block_with_scope(if_statement.else_branch.(p.Block), scope)
	case:
		return
	}
}

// Make sure the expression's elements are only accessing values they have access to
@(private = "file")
evaluate_expression_with_scope :: proc(expr: p.Expression, scope: ^Scope) -> (err := ScopeError{ok = true}) {
	switch _ in expr {
	case p.FunctionCall:
		func_call := expr.(p.FunctionCall)

		err = evaluate_name_ref_with_scope(func_call.name, .Function, scope^)
		if !err.ok do return

		for arg in func_call.args {
			err = evaluate_expression_with_scope(arg, scope)
			if !err.ok do return
		}

	// TODO: evaluate that expressions fit func args

	case p.Operation:
		op := expr.(p.Operation)

		err = evaluate_expression_with_scope(op.left^, scope)
		if !err.ok do return
		err = evaluate_expression_with_scope(op.right^, scope)
		if !err.ok do return
	case p.FormatString:
		panic("todo") // TODO: parse FormatString expressions
	case p.NameReference:
		err = evaluate_name_ref_with_scope(expr.(p.NameReference), .Variable, scope^)
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
