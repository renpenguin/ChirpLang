package parser

import t "../tokeniser"

// Block of code delimited by `{}`
Block :: distinct [dynamic]Statement

// Recursively destroy everything stored in the block
destroy_block :: proc(block: Block) {
	for instruction in block {
		switch _ in instruction {
		case ImportStatement:
			import_statement := instruction.(ImportStatement)
			for library in import_statement {
				destroy_name_ref(library)
			}
			delete(import_statement)
		case VariableDefinition:
			var_def := instruction.(VariableDefinition)
			delete(string(var_def.name))
			destroy_expression(var_def.expr)

		case VariableAssignment:
			var_ass := instruction.(VariableAssignment)
			destroy_name_ref(var_ass.target)
			destroy_expression(var_ass.expr)

		case FunctionDefinition:
			func_def := instruction.(FunctionDefinition)
			delete(string(func_def.name))
			for arg in func_def.args {
				delete(string(arg.name))
			}
			delete(func_def.args)
			destroy_block(func_def.block)

		case Forever:
			destroy_block(instruction.(Forever).block)

		case Expression:
			destroy_expression(instruction.(Expression))

		case Return:
			destroy_expression(Expression(instruction.(Return)))
		}

	}
	delete(block)
}

// Destroys the contents of an `Expression`. Do not expect this procedure to free the expression itself
destroy_expression :: proc(expr: Expression) {
	using t

	switch _ in expr {
	case FunctionCall:
		func_call := expr.(FunctionCall)
		destroy_name_ref(func_call.name)
		for arg in func_call.args {
			destroy_expression(arg)
		}
		delete(func_call.args)
	case Operation:
		operation := expr.(Operation)
		destroy_expression(operation.left^)
		destroy_expression(operation.right^)
		free(operation.left)
		free(operation.right)
	case FormatString:
		delete(string(expr.(FormatString)))
	case Value:
		if str_value, ok := expr.(Value).(string); ok do delete(str_value)
	case NameReference:
		destroy_name_ref(expr.(NameReference))
	}
}
