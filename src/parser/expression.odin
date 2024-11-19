package parser

import t "../tokeniser"
import "core:fmt"

// Calls a function with the given name and passes a list of arguments. Expected pattern `$name$($expr$, ...)``
FunctionCall :: struct {
	name: NameReference,
	args: [dynamic]Expression,
}

Operation :: struct {
	left, right: ^Expression, // is this a good idea?
	op:          t.ArithmeticOperator,
}

FormatString :: distinct string // replace with array of unions..?

// Block of code delimited by `()` that evaluates to one value
Expression :: union { // TODO: make no_nil
	FunctionCall,
	Operation,
	FormatString,
	Value,
	NameReference,
}

// Builds an Expression out of the loaded tokens
build_expression :: proc(
	tokens: t.TokenStream,
) -> (
	expr: Expression,
	err := SyntaxError{ok = true},
) {
	using t
	stored_operator: ArithmeticOperator
	state: enum {
		StoredPart,
		StoredPartAndOperator,
		None,
	} = .None

	for i := 0; i < len(tokens); i += 1 {
		to_store: Maybe(Expression) = nil

		if op, ok := tokens[i].(Operator); ok {
			arith_op, ok := op.(ArithmeticOperator)
			if !ok {
				return nil, SyntaxError {
					error_msg = "Invalid expression: expected arithmetic operator",
					found = Token(op),
				}
			}

			switch state {
			case .StoredPart:
				stored_operator = arith_op
				state = .StoredPartAndOperator
			case .StoredPartAndOperator:
				return nil, SyntaxError {
					error_msg = "Invalid expression: operator follows other operator",
				}
			// Combine expressions into operation
			case .None:
				// TODO: handle Neg and Not here
				return nil, SyntaxError {
					error_msg = "Invalid expression: operator does not follow expression ",
				}
			}

			continue
		}

		if literal, ok := tokens[i].(Literal); ok { 	// Literal
			to_store = literal_to_value(literal)
		} else if tokens[i] == Token(Keyword(.FString)) { 	// f-string
			FSTRING_ERROR_MSG :: "Invalid expression: Expected string literal after `f` keyword"
			if i + 1 >= len(tokens) do return nil, SyntaxError{error_msg = FSTRING_ERROR_MSG}

			literal, lit_ok := tokens[i + 1].(Literal)
			if !lit_ok do return nil, SyntaxError{error_msg = FSTRING_ERROR_MSG, found = Token(literal)}
			str, str_ok := literal.(string)
			if !str_ok do return nil, SyntaxError{error_msg = FSTRING_ERROR_MSG, found = Token(literal)}

			i += 1
			to_store = FormatString(str)
		} else if keyword, ok := tokens[i].(Keyword); ok { 	// Custom keyword
			custom_keyword, ok := keyword.(CustomKeyword)
			if !ok do return nil, SyntaxError{error_msg = "Invalid expression: Expected custom keyword", found = Token(keyword)}

			if i + 1 < len(tokens) && tokens[i + 1] == Token(Bracket{.Round, .Opening}) {
				i += 1
				func_call := FunctionCall {
					name = keyword_to_name_ref(custom_keyword),
				}

				was_comma := true
				for was_comma {
					found_arg: Maybe(Expression)
					found_arg, err, was_comma = capture_arg_until_closing_bracket(tokens, &i)
					if !err.ok do return
					if arg, ok := found_arg.?; ok do append(&func_call.args, arg)
				}

				to_store = func_call

			} else {
				to_store = keyword_to_name_ref(custom_keyword)
			}
		} else if tokens[i] == Token(Bracket{.Round, .Opening}) { 	// Nested expression
			was_comma: bool
			to_store, err, was_comma = capture_arg_until_closing_bracket(tokens, &i)
			if !err.ok do return
			if to_store == nil do return nil, SyntaxError{error_msg = "Invalid expression: found empty expression `()`"}
			if was_comma do return nil, SyntaxError{error_msg = "Invalid expression: comma found separating values in expression"}
		}

		s, ok := to_store.?
		if !ok do return nil, SyntaxError{error_msg = "Invalid expression", found = Token(tokens[i])}
		if ok {
			switch state {
			case .StoredPart:
				return nil, SyntaxError {
					error_msg = "Invalid expression: literal follows other expression",
				}
			case .StoredPartAndOperator:
				// Combine expressions into one operation
				operation := Operation {
					left  = new(Expression),
					right = new(Expression),
					op    = stored_operator,
				}
				operation.left^ = expr
				operation.right^ = s
				expr = Expression(operation)
				state = .StoredPart
			case .None:
				expr = s
				state = .StoredPart
			}
		}
	}

	#partial switch state {
	case .StoredPartAndOperator:
		return nil, SyntaxError{error_msg = "Invalid expression: found trailing operator"}
	case .None:
		return nil, SyntaxError{error_msg = "Empty expression"}
	}

	return
}

// Captures all `Token`s until a newline into an `Expression`
@(private)
capture_expression :: proc(
	tokens: t.TokenStream,
	token_index: ^int,
) -> (
	expr: Expression,
	err: SyntaxError,
) {
	captured_tokens: t.TokenStream
	defer delete(captured_tokens)

	for token_index^ < len(tokens) {
		if t.is_new_line(tokens[token_index^]) do break

		append(&captured_tokens, tokens[token_index^])
		token_index^ += 1
	}

	return build_expression(captured_tokens)
}

// Captures all `Token`s until a newline or comma into an `Expression`. The last value will be true if it was a comma. If no expression is found in the closing bracket, the returned Maybe(Expression) will be nil
@(private = "file")
capture_arg_until_closing_bracket :: proc(
	tokens: t.TokenStream,
	token_index: ^int,
) -> (
	expr: Maybe(Expression),
	err: SyntaxError,
	was_comma: bool,
) {
	using t
	captured_tokens: TokenStream
	defer delete(captured_tokens)

	bracket_depth := 1
	for bracket_depth > 0 {
		token_index^ += 1
		token := tokens[token_index^]
		if token == Token(Bracket{.Round, .Opening}) do bracket_depth += 1
		if token == Token(Bracket{.Round, .Closing}) do bracket_depth -= 1

		append(&captured_tokens, token)
		if token == Token(Comma) && bracket_depth == 1 {
			was_comma = true
			break
		}
	}
	pop(&captured_tokens) // Remove last `)`

	if len(captured_tokens) == 0 do return nil, SyntaxError{ok=true}, was_comma

	return build_expression(captured_tokens), was_comma
}
