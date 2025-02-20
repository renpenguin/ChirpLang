package parser

import t "../tokeniser"
import "core:strings"
import "core:fmt"

// On execution, evaluates and combines the `Expressions`. Expected pattern `f$str_lit$`
FormatString :: [dynamic]Expression

// Attempt to build a `FormatString` from the passed `Token` (which should be the string to be parsed)
build_fstring :: proc(token: t.Token) -> (fmt_str: FormatString, err := SyntaxError{ok=true}) {
	FSTRING_ERROR_MSG :: "Invalid expression: Expected string literal after `f` keyword"

	literal, lit_ok := token.(t.Literal)
	if !lit_ok do return {}, SyntaxError{msg = FSTRING_ERROR_MSG, found = token}
	str, str_ok := literal.(string)
	if !str_ok do return {}, SyntaxError{msg = FSTRING_ERROR_MSG, found = token}
	defer delete(str)

	next_arg := strings.builder_make()
	defer strings.builder_destroy(&next_arg)
	building: enum {
		Str,
		Expr,
	} = .Str

	for i := 0; i < len(str); i += 1 {
		c := str[i]
		switch building {
		case .Str:
			if c != '{' do strings.write_byte(&next_arg, c)
			else if i < len(str) - 1 && str[i + 1] == '{' { 	// Escape {{ to just {
				strings.write_byte(&next_arg, c)
				i += 1
				continue
			}

			if c == '{' || i == len(str) - 1 {
				append(&fmt_str, Value(strings.clone(strings.to_string(next_arg))))
				building = .Expr
				strings.builder_reset(&next_arg)
			}
		case .Expr:
			if c != '}' do strings.write_byte(&next_arg, c)

			if c == '}' || i == len(str) - 1 {
				fstring_tokens := t.tokenise(strings.to_string(next_arg))
				defer delete(fstring_tokens)

				fstring_expr: Expression
				fstring_expr, err = build_expression(fstring_tokens)
				if !err.ok do return

				append(&fmt_str, fstring_expr)
				building = .Str
				strings.builder_reset(&next_arg)
			}
		}
	}
	return
}

// Calls a function with the given name and passes a list of arguments. Expected pattern `$name$($expr$, ...)`
FunctionCall :: struct {
	name: NameReference,
	args: [dynamic]Expression,
}

// Attempt to build a `FunctionCall` from the passed location in the TokenStream
build_function :: proc(func_name: NameReference, tokens: t.TokenStream, char_index: ^int) -> (func_call: FunctionCall, success: bool, err := SyntaxError{ok=true}) {
	if char_index^ + 1 >= len(tokens) || tokens[char_index^ + 1] != t.Token(t.Bracket{.Round, .Opening}) {
		return
	}
	success = true

	func_call = FunctionCall{name = func_name}
	char_index^ += 1

	was_comma := true
	for was_comma {
		found_arg: Maybe(Expression)
		found_arg, err, was_comma = capture_arg_until_closing_bracket(tokens, char_index)
		if !err.ok do return
		if arg, ok := found_arg.?; ok do append(&func_call.args, arg)
	}
	return
}

// Captures all `Token`s until a newline or comma into an `Expression`. The last value will be true if it was a comma. If no expression is found in the closing bracket, the returned Maybe(Expression) will be nil
@(private)
capture_arg_until_closing_bracket :: proc(
	tokens: t.TokenStream,
	token_index: ^int,
) -> (
	expr: Maybe(Expression),
	err: SyntaxError,
	was_comma: bool,
) {
	token_index^ += 1
	expr, err = capture_expression(tokens, token_index, is_end_of_function_arg)
	if err.msg == "Empty expression" {expr = nil;err.ok = true}

	_, was_comma = tokens[token_index^].(t.CommaType)
	return
}

@(private = "file")
is_end_of_function_arg :: proc(token: t.Token) -> bool {
	_, is_comma := token.(t.CommaType)
	return is_comma || token == t.Token(t.Bracket{.Round, .Closing})
}
