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

try_match_to_literal :: proc(input_chars: []rune, i: ^int) -> (literal: Literal, ok: bool) {
	c := input_chars[i^]

	// Boolean literals
	if (len(input_chars) - i^) > 4 && utf8.runes_to_string(input_chars[i^:i^ + 5]) == "false" {
		i^ += 4
		return false, true
	}
	if (len(input_chars) - i^) > 3 && utf8.runes_to_string(input_chars[i^:i^ + 4]) == "true" {
		i^ += 3
		return true, true
	}

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

	// Number literals
	literal, ok = try_match_to_number(input_chars, i)
	if ok do return

	return
}

@(private = "file")
try_match_to_number :: proc(input_chars: []rune, i: ^int) -> (literal: Literal, ok: bool) {
	c := input_chars[i^]

	if unicode.is_number(c) {
		number_literal := int(c) - 48

		for j := i^ + 1; j < len(input_chars); j += 1 {
			c := input_chars[j]
			if !unicode.is_number(c) do break

			number_literal *= 10
			number_literal += (int(c) - 48) // Unicode offset
			i^ += 1
		}
		if input_chars[i^ + 1] != '.' do return Literal(number_literal), true

		// Float
		i^ += 1
		float_literal := float(number_literal)
		multiplier := 1.0
		for j := i^ + 1; j < len(input_chars); j += 1 {
			c := input_chars[j]
			if !unicode.is_number(c) do break

			i^ += 1
			multiplier /= 10
			float_literal += multiplier * float(int(c) - 48) // Unicode offset
		}

		return Literal(float_literal), true
	}

	return
}
