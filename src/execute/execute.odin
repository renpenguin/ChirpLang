package execute

import "core:fmt"
import p "../parser"
import s "../scope"

execute_block :: proc(block: p.Block, scope: s.Scope) -> RuntimeError {
	scope := scope
	using p

	for instruction in block {
		switch _ in instruction {
		case VariableDefinition:
			var_def := instruction.(p.VariableDefinition)
			append(&scope.constants, s.Variable{
				name = var_def.name,
				contents = execute_expression(var_def.expr, &scope)
			})
		case VariableAssignment:
			assign_operation(instruction.(p.VariableAssignment), &scope)
		case Forever:
			forever_block := instruction.(Forever).block
			for {
				forever_scope := s.Scope{parent_scope=&scope}
				execute_block(forever_block, forever_scope)
			}
		case Expression:
			execute_expression(instruction.(Expression), &scope)
		case ImportStatement, FunctionDefinition:
			break // Ignore
		}
	}

	return NoErrorUnit
}

execute_expression :: proc(expr: p.Expression, scope: ^s.Scope) -> (value: p.Value = p.None) {
	using p

	switch _ in expr {
	case FunctionCall:
		func_call := expr.(FunctionCall)

		item, _ := s.search_for_reference(scope, func_call.name)
		func := item.(s.Function)

		switch _ in func {
		case s.BuiltInFunction:
			func_pointer := func.(s.BuiltInFunction).func_ref

			values: [dynamic]Value
			defer delete(values)

			for expr in func_call.args {
				append(&values, execute_expression(expr, scope))
			}

			return_val, err := func_pointer(values)
			if !err.ok do panic(err.msg)
			return return_val

		case s.InterpretedFunction:
			panic("todo") // TODO: build scope for the function and execute its block with that scope
		}
	case Operation:
		op := expr.(p.Operation)
		output, err := process_operation(execute_expression(op.left^, scope), execute_expression(op.right^, scope), op.op)
		// TODO: handle type errors
		return output
	case FormatString:
		panic("todo") // TODO: implement string formatting. code below should return a string
	case Value:
		return expr.(Value)
	case NameReference:
		name_ref := expr.(NameReference)
		variable, _ := s.search_for_reference(scope, name_ref)

		return variable.(^s.Variable).contents
	}

	return
}
