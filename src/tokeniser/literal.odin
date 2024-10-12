package tokeniser

import "core:unicode"
import "core:unicode/utf8"

Literal :: union #no_nil {
	string,
	int,
}

try_match_to_literal :: proc(input_chars: []rune, i: ^int) -> (literal: Literal, ok: bool) {
	c := input_chars[i^]

	// String literals
	if c == '"' || c == '\'' {
		string_runes: [dynamic]rune
		defer delete(string_runes)

		for j := i^ + 1; j < len(input_chars); j += 1 {
			c := input_chars[j]
			i^ += 1
			if c == '"' || c == '\'' { 	// TODO: handle \" and \'
				break
			} else {
				append(&string_runes, c)
			}
		}

		return Literal(utf8.runes_to_string(string_runes[:])), true
	}

	// Integer literals
	if unicode.is_number(c) {
		number_literal := int(c) - 48

		for j := i^ + 1; j < len(input_chars); j += 1 {
			c := input_chars[j]
			if unicode.is_number(c) {
				number_literal *= 10
				number_literal += (int(c) - 48) // Unicode offset
				i^ += 1
			} else {
				break
			}
		}

		return Literal(number_literal), true
	}

	return 0, false
}
