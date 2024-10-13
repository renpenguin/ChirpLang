package parser

import t "../tokeniser"
import "core:fmt"

// Calls a function with the given name and passes a list of arguments. Expected pattern `$name$($expr$, ...)``
FunctionCall :: struct {
	name: t.CustomKeyword,
	args: [dynamic]Expression,
}

Operation :: struct {
	left, right: ^Expression, // is this a good idea?
	op:          t.ArithmeticOperator,
}

FormatString :: distinct string

// Block of code delimited by `()` that evaluates to one value
Expression :: union {
	FunctionCall,
	Operation,
	FormatString,
	t.Literal,
	t.CustomKeyword,
}

// Captures all `Token`s until a newline into an `Expression`
capture_expression :: proc(
	tokens: t.TokenStream,
	token_index: ^int,
) -> (
	expr: Expression,
	err: ParseError,
) {
	captured_tokens: t.TokenStream
	defer delete(captured_tokens)

	for token_index^ < len(tokens) {
		if t.is_new_line(tokens[token_index^]) do break

		append(&captured_tokens, tokens[token_index^])
		token_index^ += 1
	}

	return evaluate_expression(captured_tokens)
}

// Captures all `Token`s until a newline or comma into an `Expression`. The last value will be true if it was a comma
capture_arg_until_closing_bracket :: proc(
	tokens: t.TokenStream,
	token_index: ^int,
) -> (
	expr: Expression,
	err: ParseError,
	was_comma: bool,
) {
	captured_tokens: t.TokenStream
	defer delete(captured_tokens)

	when ODIN_DEBUG do fmt.print("Captured tokens for expression [[ ")

	bracket_depth := 1
	for bracket_depth > 0 {
		token_index^ += 1
		token := tokens[token_index^]
		if token == t.Token(t.Bracket{.Round, .Opening}) do bracket_depth += 1
		if token == t.Token(t.Bracket{.Round, .Closing}) do bracket_depth -= 1

		when ODIN_DEBUG do fmt.print(token, ", ", sep = "")

		append(&captured_tokens, token)
		if token == t.Token(t.Comma) && bracket_depth == 1 {
			was_comma = true
			break
		}
	}
	pop(&captured_tokens) // Remove last )

	when ODIN_DEBUG do fmt.println("]] into", captured_tokens)

	return evaluate_expression(captured_tokens), was_comma
}

evaluate_expression :: proc(tokens: t.TokenStream) -> (expr: Expression, err: ParseError) {
	err = ParseError {
		ok = true,
	}
	stored_part: Expression
	stored_operator: t.ArithmeticOperator
	state: enum {
		StoredPart,
		StoredPartAndOperator,
		None,
	} = .None

	for i := 0; i < len(tokens); i += 1 {
		to_store: Maybe(Expression) = nil

		if op, ok := tokens[i].(t.Operator); ok {
			arith_op, ok := op.(t.ArithmeticOperator)
			if !ok {
				return nil, ParseError {
					error_msg = "Invalid expression: expected arithmetic operator",
					found = t.Token(op),
				}
			}

			switch state {
			case .StoredPart:
				stored_operator = arith_op
				state = .StoredPartAndOperator
			case .StoredPartAndOperator:
				return nil, ParseError {
					error_msg = "Invalid expression: operator follows other operator",
				}
			// Combine expressions into operation
			case .None:
				// TODO: handle Neg and Not here
				return nil, ParseError {
					error_msg = "Invalid expression: operator does not follow expression ",
				}
			}

			continue
		}

		if literal, ok := tokens[i].(t.Literal); ok {
			to_store = literal
		} else if tokens[i] == t.Token(t.Keyword(.FString)) {
			FSTRING_ERROR_MSG :: "Invalid expression: Expected string literal after `f` keyword"
			if i + 1 >= len(tokens) do return nil, ParseError { error_msg = FSTRING_ERROR_MSG }

			literal, lit_ok := tokens[i + 1].(t.Literal)
			if !lit_ok do return nil, ParseError { error_msg = FSTRING_ERROR_MSG, found = t.Token(literal) }
			str, str_ok := literal.(string)
			if !str_ok do return nil, ParseError { error_msg = FSTRING_ERROR_MSG, found = t.Token(literal) }

			i += 1
			to_store = FormatString(str)
		} else if keyword, ok := tokens[i].(t.Keyword); ok {
			custom_keyword, ok := keyword.(t.CustomKeyword)
			if !ok do return nil, ParseError { error_msg = "Invalid expression: Expected custom keyword", found = t.Token(keyword) }

			if i + 1 < len(tokens) && tokens[i + 1] == t.Token(t.Bracket{.Round, .Opening}) {
				i += 1
				func_call := FunctionCall {
					name = custom_keyword,
				}

				was_comma := true
				for was_comma {
					arg: Expression
					arg, err, was_comma = capture_arg_until_closing_bracket(tokens, &i)
					if !err.ok do return

					append(&func_call.args, arg)
				}

				to_store = func_call

			} else {
				to_store = custom_keyword
			}
		}

		if tokens[i] == t.Token(t.Bracket{.Round, .Opening}) {
			was_comma: bool
			to_store, err, was_comma = capture_arg_until_closing_bracket(tokens, &i)
			if !err.ok do return
			if was_comma do return nil, ParseError{error_msg = "Invalid expression: comma found separating values in expression"}
		}

		if s, ok := to_store.?; ok {
			switch state {
			case .StoredPart:
				return nil, ParseError {
					error_msg = "Invalid expression: literal follows other expression",
				}
			case .StoredPartAndOperator:
				// Combine expressions into operation
				when ODIN_DEBUG do fmt.println(
					"Combining expressions",
					stored_part,
					"and",
					s,
					"into operation",
					stored_operator,
				)
				operation := Operation {
					left  = new(Expression),
					right = new(Expression),
					op    = stored_operator,
				}
				operation.left^ = stored_part
				operation.right^ = s
				stored_part = Expression(operation)
				state = .StoredPart
			case .None:
				stored_part = s
				state = .StoredPart
			}
		}
	}

	switch state {
	case .StoredPart:
		return stored_part, ParseError{ok = true}
	case .StoredPartAndOperator:
		return nil, ParseError{error_msg = "Invalid expression: found trailing operator"}
	case .None:
		return nil, ParseError{error_msg = "Empty expression"}
	}

	panic("Unreachable")
}
