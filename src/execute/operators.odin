package execute

import p "../parser"
import s "../scope"
import t "../tokeniser"

assign_operation :: proc(assignment: p.VariableAssignment, scope: ^s.Scope) -> (err: RuntimeError = NoErrorUnit) {
	scope_item, _ := s.search_for_reference(scope, assignment.target)
	variable := scope_item.(^s.Variable)

	expr_result, new_val: p.Value

	operator: t.ArithmeticOperator
	switch assignment.operator {
	case .AddAssign:
		operator = .Add
	case .SubAssign:
		operator = .Sub
	case .MulAssign:
		operator = .Mul
	case .DivAssign:
		operator = .Div
	case .Assign:
		new_val, err = execute_expression(assignment.expr, scope)
		if !is_runtime_error_ok(err) do return err
		// TODO: type checking
		variable.contents = new_val
		return
	}

	expr_result, err = execute_expression(assignment.expr, scope)
	if !is_runtime_error_ok(err) do return err

	new_val, err = process_operation(
		variable.contents,
		expr_result,
		operator,
	)
	if !is_runtime_error_ok(err) do return err
	// TODO: type checking
	variable.contents = new_val

	return
}

process_operation :: proc(
	value1, value2: p.Value,
	operator: t.ArithmeticOperator,
) -> (
	output: p.Value,
	err := TypeError{ok = true},
) {
	type1 := p.get_value_type(value1)
	type2 := p.get_value_type(value2)

	switch type1 {
	case .Int:
		first := value1.(int)
		second, ok := value2.(int)
		if !ok {
			float_second: t.float
			float_second, ok = value2.(t.float)
			if !ok do return p.None, TypeError{msg = "Cannot operate on values", values = [dynamic]p.ValueType{type1, type2}}
			second = int(float_second)
		}

		#partial switch operator {
		case .Add:
			return first + second, err
		case .Sub:
			return first - second, err
		case .Mul:
			return first * second, err
		case .Div:
			return first / second, err
		case .NotEqual:
			return first != second, err
		case .IsEqual:
			return first == second, err
		case .GreaterThan:
			return first > second, err
		case .GreaterEqual:
			return first >= second, err
		case .LessThan:
			return first < second, err
		case .LessEqual:
			return first <= second, err
		case:
			return p.None, TypeError{msg = "Operation cannot be performed on int values", op = operator}
		}
	case .Float:
		first := value1.(t.float)
		second, ok := value2.(t.float)
		if !ok {
			float_second: int
			float_second, ok = value2.(int)
			if !ok do return p.None, TypeError{msg = "Cannot operate on values", values = [dynamic]p.ValueType{type1, type2}}
			second = t.float(float_second)
		}

		#partial switch operator {
		case .Add:
			return first + second, err
		case .Sub:
			return first - second, err
		case .Mul:
			return first * second, err
		case .Div:
			return first / second, err
		case .NotEqual:
			return first != second, err
		case .IsEqual:
			return first == second, err
		case .GreaterThan:
			return first > second, err
		case .GreaterEqual:
			return first >= second, err
		case .LessThan:
			return first < second, err
		case .LessEqual:
			return first <= second, err
		case:
			return p.None, TypeError{msg = "Operation cannot be performed on float values", op = operator}
		}
	case .Bool:
		first := value1.(bool)
		second, ok := value2.(bool)

		#partial switch operator {
		case .And:
			return first && second, err
		case .Or:
			return first || second, err
		case .NotEqual:
			return first != second, err
		case .IsEqual:
			return first == second, err
		case:
			return p.None, TypeError{msg = "Operation cannot be performed on bool values", op = operator}
		}
	case .String, .None:
		break
	}

	return p.None, TypeError{msg = "Operation unavailable for values"}
}
