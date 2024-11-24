package execute

import p "../parser"
import s "../scope"
import t "../tokeniser"
import "core:fmt"

execute_block :: proc(
	block: p.Block,
	scope: s.Scope,
) -> (
	return_val: p.Value = p.None,
	err: RuntimeError = NoErrorUnit,
) {
	scope := scope
	using p

	for instruction in block {
		switch _ in instruction {
		case VariableDefinition:
			var_def := instruction.(p.VariableDefinition)

			contents: p.Value
			contents, err = execute_expression(var_def.expr, &scope)
			if !is_runtime_error_ok(err) do return

			append(&scope.constants, s.Variable{name = var_def.name, contents = contents})
		case VariableAssignment:
			err = assign_operation(instruction.(p.VariableAssignment), &scope)
			if !is_runtime_error_ok(err) do return
		case Forever:
			forever_block := instruction.(Forever).block
			for {
				forever_scope := s.Scope {
					parent_scope = &scope,
				}
				defer s.destroy_scope(forever_scope)
				_, err = execute_block(forever_block, forever_scope)
				if !is_runtime_error_ok(err) do return p.None, err
			}
		case Expression:
			_, err = execute_expression(instruction.(Expression), &scope)
			if !is_runtime_error_ok(err) do return p.None, err
		case p.Return:
			return_val, err = execute_expression(Expression(instruction.(Return)), &scope)
			if !is_runtime_error_ok(err) do return p.None, err
			return

		case ImportStatement, FunctionDefinition:
			break // Ignore
		}
	}

	return
}

@(private)
execute_expression :: proc(
	expr: p.Expression,
	scope: ^s.Scope,
) -> (
	value: p.Value = p.None,
	err: RuntimeError = NoErrorUnit,
) {
	using p

	switch _ in expr {
	case FunctionCall:
		return call_function(expr.(p.FunctionCall), scope)
	case Operation:
		op := expr.(p.Operation)

		value1, value2, output: Value

		value1, err = execute_expression(op.left^, scope)
		if !is_runtime_error_ok(err) do return
		value2, err = execute_expression(op.right^, scope)
		if !is_runtime_error_ok(err) do return

		output, err = process_operation(value1, value2, op.op)
		if !is_runtime_error_ok(err) do return

		return output, err
	case FormatString:
		panic("todo") // TODO: implement string formatting. code below should return a string
	case Value:
		return expr.(Value), err
	case NameReference:
		name_ref := expr.(NameReference)
		variable, _ := s.search_for_reference(scope, name_ref)

		return variable.(^s.Variable).contents, err
	}

	return
}

call_function :: proc(
	func_call: p.FunctionCall,
	scope: ^s.Scope,
) -> (
	return_val: p.Value = p.None,
	err: RuntimeError,
) {
	item, _ := s.search_for_reference(scope, func_call.name)
	func := item.(s.Function)

	switch _ in func {
	case s.BuiltInFunction:
		func_pointer := func.(s.BuiltInFunction).func_ref

		values: [dynamic]p.Value
		defer delete(values)

		for expr in func_call.args {
			arg: p.Value
			arg, err = execute_expression(expr, scope)
			if !is_runtime_error_ok(err) do return
			append(&values, arg)
		}

		return_val, err = func_pointer(values)

	case s.InterpretedFunction:
		interp_func_def := func.(s.InterpretedFunction)

		func_scope := s.Scope {
			parent_scope = scope,
		}
		defer s.destroy_scope(func_scope)

		if len(interp_func_def.args) != len(func_call.args) do return p.None, s.BuiltInFunctionError{msg = "Incorrect number of arguments passed to function call"}
		for def_arg, i in interp_func_def.args {
			passed_arg: p.Value
			passed_arg, err = execute_expression(func_call.args[i], scope)
			if !is_runtime_error_ok(err) do return
			if def_arg.type != p.get_value_type(passed_arg) do return p.None, s.BuiltInFunctionError{msg = "Incorrect argument type"}

			append(&func_scope.constants, s.Variable{def_arg.name, passed_arg})
		}

		return_val, err = execute_block(interp_func_def.block, func_scope)
		if !is_runtime_error_ok(err) do return

		// Handle return values
		if p.get_value_type(return_val) != interp_func_def.return_type {
			err = TypeError {
				msg    = "Function return value does not match return type",
				value1 = p.get_value_type(return_val),
				value2 = interp_func_def.return_type,
			}
		}
	}
	return
}
