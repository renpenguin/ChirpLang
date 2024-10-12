package tokeniser

NewLineType :: struct {
	count: uint,
} 	// unique zero-sided type

NewLine :: NewLineType{1} // shorthand to avoid having to add braces every time i want to define a comma

append_new_line :: proc(tokens: ^[dynamic]Token) {
	previous_token, was_new_line := tokens[len(tokens) - 1].(NewLineType)
	if !was_new_line {
		append(tokens, NewLine)
	} else if previous_token.count < MAX_ALLOWED_NEWLINES {
		previous_token.count += 1
		tokens[len(tokens) - 1] = previous_token
	}
}

smart_pop :: proc(tokens: ^[dynamic]Token) {
	previous_token, was_new_line := tokens[len(tokens) - 1].(NewLineType)
	if !was_new_line || previous_token.count == 1 {
		pop(tokens)
	} else {
		previous_token.count -= 1
		tokens[len(tokens) - 1] = previous_token
	}
}
