package tokeniser

import "core:unicode"
import "core:unicode/utf8"

float :: f64

Literal :: union #no_nil {
	bool,
	string,
	int,
	float,
}

@(private)
// Attempts to map the custom keyword onto a `true` or `false` literal. Consumes the keyword if successful
try_match_keyword_to_bool_literal :: proc(keyword: Keyword) -> (literal: Maybe(Literal)) {
	if keyword == CustomKeyword("true") do literal = true
	if keyword == CustomKeyword("false") do literal = false

	_, did_match := literal.?
	if did_match do delete(string(keyword.(CustomKeyword)))

	return
}

@(private)
// Attempts to match a leading `string`, `int` or `float` literal. Boolean literals are handled in `tokenise_next_char`
try_match_to_literal :: proc(
	input_chars: []rune,
	char_index: ^int,
) -> (
	literal: Literal,
	ok: bool,
) {
	c := input_chars[char_index^]

	// String literals
	if c == '"' || c == '\'' {
		string_runes: [dynamic]rune
		defer delete(string_runes)

		collect_runes: for j := char_index^ + 1; j < len(input_chars); j += 1 {
			c := input_chars[j]
			char_index^ += 1

			switch c {
			case '"', '\'':
				break collect_runes
			case '\\':
				char_index^ += 1
				j += 1
				append(&string_runes, input_chars[j])
			case:
				append(&string_runes, c)
			}
		}

		return Literal(utf8.runes_to_string(string_runes[:])), true
	}

	// Number literals
	if literal, ok = try_match_to_number(input_chars, char_index); ok do return

	return
}

@(private = "file")
try_match_to_number :: proc(
	input_chars: []rune,
	char_index: ^int,
) -> (
	literal: Literal,
	ok: bool,
) {
	c := input_chars[char_index^]

	if unicode.is_number(c) {
		number_literal := int(c) - 48

		for j := char_index^ + 1; j < len(input_chars); j += 1 {
			c := input_chars[j]
			if !unicode.is_number(c) do break

			number_literal *= 10
			number_literal += (int(c) - 48) // Unicode offset
			char_index^ += 1
		}
		if (char_index^ + 1) >= len(input_chars) do return Literal(number_literal), true // EOF
		if input_chars[char_index^ + 1] != '.' do return Literal(number_literal), true // Guard for float parsing

		// Float
		char_index^ += 1
		float_literal := float(number_literal)
		multiplier := 1.0
		for j := char_index^ + 1; j < len(input_chars); j += 1 {
			c := input_chars[j]
			if !unicode.is_number(c) do break

			char_index^ += 1
			multiplier /= 10
			float_literal += multiplier * float(int(c) - 48) // Unicode offset
		}

		return Literal(float_literal), true
	}

	return
}
