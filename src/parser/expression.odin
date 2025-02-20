package parser

import t "../tokeniser"
import "core:fmt"

Operation :: struct {
	left, right: ^Expression, // is this a good idea?
	op:          t.ArithmeticOperator,
}

// Block of code delimited by `()` that evaluates to one value
Expression :: union #no_nil {
	FunctionCall,
	Operation,
	FormatString,
	Value,
	NameReference,
}

// Captures all `Token`s until a newline (and all opened brackets have been closed) into an `Expression`
@(private)
capture_expression :: proc(
	tokens: t.TokenStream,
	token_index: ^int,
	end_token_matcher: proc(token: t.Token) -> bool = t.is_new_line,
) -> (
	expr: Expression,
	err: SyntaxError,
) {
	captured_tokens: t.TokenStream
	defer delete(captured_tokens)

	bracket_depth := 0
	for token_index^ < len(tokens) {
		if end_token_matcher(tokens[token_index^]) && bracket_depth == 0 do break
		if bracket, ok := tokens[token_index^].(t.Bracket); ok {
			bracket_depth += bracket.state == .Opening ? 1 : -1
			if bracket_depth < 0 do return Value(None), SyntaxError{msg = "Found closing bracket with no matching opening bracket", found = tokens[token_index^]}
		}
		append(&captured_tokens, tokens[token_index^])
		token_index^ += 1
	}

	return build_expression(captured_tokens)
}

// Builds an Expression out of the loaded tokens
build_expression :: proc(tokens: t.TokenStream) -> (expr: Expression, err := SyntaxError{ok = true}) {
	using t
	stored_operator: ArithmeticOperator
	state: enum {
		StoredPart,
		StoredPartAndOperator,
		None,
	} = .None

	for i := 0; i < len(tokens); i += 1 {
		if is_new_line(tokens[i]) do continue
		to_store: Maybe(Expression) = nil

		if op, ok := tokens[i].(Operator); ok {
			arith_op, ok := op.(ArithmeticOperator)
			if !ok do return Value(None), SyntaxError{msg = "Invalid expression: expected arithmetic operator", found = Token(op)}

			switch state {
			case .StoredPart:
				stored_operator = arith_op
				state = .StoredPartAndOperator
			case .StoredPartAndOperator:
				return Value(None), SyntaxError{msg = "Invalid expression: operator follows other operator"}
			// Combine expressions into operation
			case .None:
				if arith_op == .Not {
					panic("todo") // TODO: implement ! operator, making sure that placing it between parts is invalid
				} else if arith_op == .Sub {
					expr = Value(int(0))
					stored_operator = .Sub
				} else {
					return Value(None), SyntaxError{msg = "Invalid expression: operator does not follow expression "}
				}
			}

			continue
		}

		if literal, ok := tokens[i].(Literal); ok { 	// Literal
			to_store = literal_to_value(literal)
		} else if tokens[i] == Token(Keyword(.FString)) { 	// f-string
			i += 1
			to_store, err = build_fstring(tokens[i])
			if !err.ok do return
		} else if keyword, ok := tokens[i].(Keyword); ok { 	// Custom keyword
			custom_keyword, ok := keyword.(CustomKeyword)
			if !ok do return Value(None), SyntaxError{msg = "Invalid expression: Expected custom keyword", found = Token(keyword)}
			name_ref := keyword_to_name_ref(custom_keyword)

			// Try function
			to_store, err, ok = build_function(name_ref, tokens, &i)
			if !err.ok do return
			if !ok do to_store = name_ref // If failed, must be variable reference
		} else if tokens[i] == Token(Bracket{.Round, .Opening}) { 	// Nested expression
			was_comma: bool
			to_store, err, was_comma = capture_arg_until_closing_bracket(tokens, &i)
			if !err.ok do return
			if to_store == nil do return Value(None), SyntaxError{msg = "Invalid expression: found empty expression `()`"}
			if was_comma do return Value(None), SyntaxError{msg = "Invalid expression: comma found separating values in expression"}
		}

		s, ok := to_store.?
		if !ok do return Value(None), SyntaxError{msg = "Invalid expression", found = Token(tokens[i])}
		if ok {
			switch state {
			case .StoredPart:
				return Value(None), SyntaxError{msg = "Invalid expression: literal follows other expression"}
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
		return Value(None), SyntaxError{msg = "Invalid expression: found trailing operator"}
	case .None:
		return Value(None), SyntaxError{msg = "Empty expression"}
	}

	return
}
