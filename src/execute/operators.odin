package execute

import p "../parser"
import s "../scope"
import t "../tokeniser"

@(private)
assign_operation :: proc(assignment: p.VariableAssignment, scope: ^s.Scope) -> (err: RuntimeError = NoErrorUnit) {
	scope_item, _ := s.search_for_reference(scope, assignment.target)
	variable := scope_item.(^s.Variable)

	expr_result, new_val: RTValue

	if assignment.operator == .Assign {
		new_val, err = execute_expression(assignment.expr, scope)
		if !is_runtime_error_ok(err) do return err
	} else {
		operator: t.ArithmeticOperator
		switch assignment.operator {
		case .AddAssign: operator = .Add
		case .SubAssign: operator = .Sub
		case .MulAssign: operator = .Mul
		case .DivAssign: operator = .Div
		case .Assign: break
		}

		expr_result, err = execute_expression(assignment.expr, scope)
		if !is_runtime_error_ok(err) do return err

		new_val, err = process_operation(variable.contents, expr_result, operator)
		if !is_runtime_error_ok(err) do return err
	}

	// TODO: type checking
	free_value(variable.contents)
	variable.contents = new_val

	return
}

@(private)
process_operation :: proc(
	value1, value2: RTValue,
	operator: t.ArithmeticOperator,
) -> (
	output: RTValue,
	err := TypeError{ok = true},
) {
	value1, value2, ok := match_types(value1, value2)
	// free_value(value1, value2)
	if !ok do return RTNone, TypeError {
		msg = "Could not match value types",
		expected = p.get_value_type(value1),
		found = p.get_value_type(value2)
	}

	switch p.get_value_type(value1) {
	case .Int:
		first := value1.(int)
		second := value2.(int)

		out: p.Value
		#partial switch operator {
		case .Add: 			out = first + second
		case .Sub: 			out = first - second
		case .Mul: 			out = first * second
		case .Div: 			out = first / second
		case .NotEqual: 	out = first != second
		case .IsEqual: 		out = first == second
		case .GreaterThan: 	out = first > second
		case .GreaterEqual: out = first >= second
		case .LessThan: 	out = first < second
		case .LessEqual: 	out = first <= second
		case: err = TypeError{msg = "Operation cannot be performed on int values", op = operator}
		}
		return RTValue(out), err
	case .Float:
		first := value1.(t.float)
		second := value2.(t.float)

		out: p.Value
		#partial switch operator {
		case .Add: 			out = first + second
		case .Sub: 			out = first - second
		case .Mul: 			out = first * second
		case .Div: 			out = first / second
		case .NotEqual: 	out = first != second
		case .IsEqual: 		out = first == second
		case .GreaterThan: 	out = first > second
		case .GreaterEqual: out = first >= second
		case .LessThan: 	out = first < second
		case .LessEqual: 	out = first <= second
		case: err = TypeError{msg = "Operation cannot be performed on float values", op = operator}
		}
		return RTValue(out), err
	case .Bool:
		first := value1.(bool)
		second := value2.(bool)

		out: p.Value
		#partial switch operator {
		case .And: 		out = first && second
		case .Or: 		out = first || second
		case .NotEqual: out = first != second
		case .IsEqual: 	out = first == second
		case: err = TypeError{msg = "Operation cannot be performed on bool values", op = operator}
		}
		return RTValue(out), err
	case .String, .None:
		break
	}

	return RTNone, TypeError{msg = "Operation unavailable for values"}
}

@(private)
match_types :: proc(value1, value2: RTValue) -> (matched_value1, matched_value2: p.Value, ok: bool) {
	value1, value2 := get_value(value1), get_value(value2)
	type1 := get_value_type(value1)
	type2 := get_value_type(value2)

	matching_types := type1 == type2
	if !matching_types {
		matching_types = true
		if type1 == .Float {
			#partial switch type2 {
			case .Int:  value2 = f64(value2.(int)); type2 = .Float
			case .Bool: value2 = value2.(bool) ? 1.0 : 0.0; type2 = .Float
			case:       matching_types = false
			}
		}

		if type1 == .Int {
			#partial switch type2 {
			case .Float: value1 = f64(value1.(int)); type1 = .Float
			case .Bool:  value2 = value2.(bool) ? 1 : 0; type2 = .Int
			case:        matching_types = false
			}
		}

		if type1 == .Bool {
			#partial switch type2 {
			case .Float: value1 = value1.(bool) ? 1 : 0; type1 = .Float
			case .Int:   value1 = value1.(bool) ? 1 : 0; type1 = .Int
			case:        matching_types = false
			}
		}

		if !matching_types do return value1, value2, false
	}

	return value1, value2, true
}
