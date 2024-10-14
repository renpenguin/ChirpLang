package tokeniser

import "core:fmt"
import "core:strings"
import "core:unicode"
import "core:unicode/utf8"

Bracket :: struct {
	type:  enum {
		Round, // Used for calling/defining functions, order of operations (expressions)
		Square, // Used to define and access arrays
		Curly, // Used for function/if/loop scope and struct/enum definitions
	} `fmt:"s"`,
	state: enum {
		Opening,
		Closing,
	} `fmt:"s"`,
}

CommaType :: struct {} // unique zero-sided type
Comma :: CommaType{} // shorthand to avoid having to add braces every time i want to define a comma

Token :: union #no_nil {
	Operator,
	Keyword,
	Bracket,
	Literal,
	CommaType,
	NewLineType,
}

// Takes a block of code in the form of plain text as parameter and returns it as a dynamic array of tokens.
// The returned dynamic array must be deleted with `delete(tokens)`.
tokenise :: proc(input: string) -> (tokens: TokenStream) {
	input_chars := utf8.string_to_runes(strings.trim_space(input))
	defer delete(input_chars)

	for i := 0; i < len(input_chars); i += 1 {
		tokenise_next_char(&tokens, input_chars, &i)
	}

	// Every tokenstream should end with one trailing new line
	append(&tokens, NewLine)

	return
}

// Capture the next
@(private = "file")
tokenise_next_char :: proc(tokens: ^TokenStream, input_chars: []rune, char_index: ^int) {
	c := input_chars[char_index^]
	if strings.is_space(c) && c != '\n' do return // Ignore whitespace

	// Handle new lines
	if c == '\n' || c == ';' {
		append_new_line(tokens)
		return
	}

	// Literals
	if literal, ok := try_match_to_literal(input_chars, char_index); ok {
		append(tokens, literal)
		return
	}

	// Operators
	if op, ok := try_match_to_assignable_operator(input_chars, char_index); ok {
		append(tokens, op)
		return
	}

	// Keywords
	if keyword, ok := try_parse_keyword(input_chars, char_index); ok {
		// Attempt to map the keyword onto `true` or `false`
		bool_literal, ok := try_match_keyword_to_bool_literal(keyword).?
		if ok do append(tokens, bool_literal)
		else do append(tokens, keyword)
		return
	}

	switch c {
	// Comma
	case ',': append(tokens, Comma)

	// Brackets
	case '(': append(tokens, Bracket{.Round, .Opening})
	case ')': append(tokens, Bracket{.Round, .Closing})
	case '[': append(tokens, Bracket{.Square, .Opening})
	case ']': append(tokens, Bracket{.Square, .Closing})
	case '{': append(tokens, Bracket{.Curly, .Opening})
	case '}':
		// If no newline before }, add a newline first
		if !is_new_line(tokens[len(tokens) - 1]) {
			append_new_line(tokens)
		}
		append(tokens, Bracket{.Curly, .Closing})

	case:
		fmt.println("unexpected token!", c)
	}
}
