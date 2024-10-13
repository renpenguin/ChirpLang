package tokeniser

@(private = "file")
MAX_ALLOWED_NEWLINES :: 2

NewLineType :: struct {
	count: uint,
}

NewLine :: NewLineType{1} // shorthand to avoid having to specify the count every time i want to indicate a newline

is_new_line :: proc(token: Token) -> bool {
	_, is_new_line := token.(NewLineType)
	return is_new_line
}

@(private)
append_new_line :: proc(tokens: ^TokenStream) {
	previous_token, was_new_line := tokens[len(tokens) - 1].(NewLineType)
	if !was_new_line {
		append(tokens, NewLine)
	} else if previous_token.count < MAX_ALLOWED_NEWLINES {
		previous_token.count += 1
		tokens[len(tokens) - 1] = previous_token
	}
}

@(private)
smart_pop :: proc(tokens: ^TokenStream) {
	previous_token, was_new_line := tokens[len(tokens) - 1].(NewLineType)
	if !was_new_line || previous_token.count == 1 {
		pop(tokens)
	} else {
		previous_token.count -= 1
		tokens[len(tokens) - 1] = previous_token
	}
}
