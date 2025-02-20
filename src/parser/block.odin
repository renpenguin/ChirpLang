package parser

import t "../tokeniser"

// Block of code delimited by `{}`
Block :: distinct [dynamic]Statement

// Recursively destroy everything stored in the block
destroy_block :: proc(block: Block) {
	for instruction in block {
		switch inst in instruction {
		case ImportStatement:
			for library in inst {
				destroy_name_ref(library)
			}
			delete(inst)

		case VariableDefinition:
			delete(string(inst.name))
			destroy_expression(inst.expr)
		case VariableAssignment:
			destroy_name_ref(inst.target)
			destroy_expression(inst.expr)

		case FunctionDefinition:
			delete(string(inst.name))
			for arg in inst.args {
				delete(string(arg.name))
			}
			delete(inst.args)
			destroy_block(inst.block)

		case While:
			destroy_expression(inst.condition)
			destroy_block(inst.block)
		case IfStatement:
			destroy_if_statement(inst)

		case Expression:
			destroy_expression(inst)

		case Return:
			destroy_expression(Expression(inst))
		case LoopControl:
			break
		}

	}
	delete(block)
}

// Destroys the contents of an `IfStatement`. Pointers in the `else_branch` proprerty are expected to be freeable
destroy_if_statement :: proc(if_stat: IfStatement) {
	destroy_expression(if_stat.condition)
	destroy_block(if_stat.true_block)
	switch branch in if_stat.else_branch {
	case ^IfStatement:
		destroy_if_statement(branch^)
		free(branch)

	case Block:
		destroy_block(branch)
	}
}

// Destroys the contents of an `Expression`. Do not expect this procedure to free the expression itself
destroy_expression :: proc(expression: Expression) {
	using t

	switch expr in expression {
	case FunctionCall:
		destroy_name_ref(expr.name)
		for arg in expr.args {
			destroy_expression(arg)
		}
		delete(expr.args)
	case Operation:
		destroy_expression(expr.left^)
		destroy_expression(expr.right^)
		free(expr.left)
		free(expr.right)
	case FormatString:
		for arg in expr do destroy_expression(arg)
		delete(expr)
	case Value:
		if str_value, ok := expr.(string); ok do delete(str_value)
	case NameReference:
		destroy_name_ref(expr)
	}
}
