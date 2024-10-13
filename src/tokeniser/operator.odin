package tokeniser

ArithmeticOperator :: enum {
	Add, // +
	Sub, // -
	Mul, // *
	Div, // /
	And, // and
	Or, // or
	Not, // !
	NotEqual, // !=
	IsEqual, // ==
	GreaterThan, // >
	GreaterEqual, // >=
	LessThan, // <
	LessEqual, // <=
}
AssignmentOperator :: enum {
	AddAssign, // +=
	SubAssign, // -=
	MulAssign, //*=
	DivAssign, // /=
	Assign, // =
}

Operator :: union {
	ArithmeticOperator,
	AssignmentOperator
}

// Attempts to match the present runes to an operator, checking for a trailing `=`
@(private)
try_match_to_assignable_operator :: proc(
	input_chars: []rune,
	char_index: ^int,
) -> (
	found_operator: Operator,
	ok: bool,
) {
	operators_with_possible_trailing_equals := map[rune]struct {
		default_op, assign_op: Operator,
	} {
		'=' = {.Assign, .IsEqual},
		'+' = {.Add, .AddAssign},
		'-' = {.Sub, .SubAssign},
		'*' = {.Mul, .MulAssign},
		'/' = {.Div, .DivAssign},
		'!' = {.Not, .NotEqual},
		'>' = {.GreaterThan, .GreaterEqual},
		'<' = {.LessThan, .LessEqual},
	}
	defer delete(operators_with_possible_trailing_equals)

	for key, value in operators_with_possible_trailing_equals {
		if input_chars[char_index^] == key {
			ok = true
			if char_index^ + 1 < len(input_chars) && input_chars[char_index^ + 1] == '=' {
				char_index^ += 1
				found_operator = value.assign_op
			} else {
				found_operator = value.default_op
			}
			break
		}
	}

	return
}
