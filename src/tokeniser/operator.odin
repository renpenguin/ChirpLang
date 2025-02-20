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
	AssignmentOperator,
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

	op, found_op := operators_with_possible_trailing_equals[input_chars[char_index^]]
	if !found_op do return
	ok = true

	if char_index^ + 1 < len(input_chars) && input_chars[char_index^ + 1] == '=' {
		char_index^ += 1
		found_operator = op.assign_op
	} else {
		found_operator = op.default_op
	}

	return
}

// Return an `and` or `or` operator if the custom keyword matches it
@(private)
try_match_keyword_to_and_or :: proc(keyword: Keyword) -> (literal: Maybe(Operator)) {
	switch keyword {
	case CustomKeyword("and"): literal = .And
	case CustomKeyword("or"): literal = .Or
	case: return nil
	}
	delete(string(keyword.(CustomKeyword)))
	return
}
