package tokeniser

import "core:unicode/utf8"

Comment :: distinct string

// Attempts to match for `//`, then reads until a newline
@(private)
try_match_to_comment :: proc(
	input_chars: []rune,
	char_index: ^int,
) -> (
	comment: Comment,
	ok: bool,
) {
	c := input_chars[char_index^]

	if c == '/' && input_chars[char_index^ + 1] == '/' {
		char_index^ += 1
		for input_chars[char_index^ + 1] == ' ' do char_index^ += 1
		comment_runes: [dynamic]rune
		defer delete(comment_runes)

		collect_runes: for j := char_index^ + 1; j < len(input_chars); j += 1 {
			c := input_chars[j]
			char_index^ += 1

			switch c {
			case '\n':
				char_index^ -= 1
				break collect_runes
			case:
				append(&comment_runes, c)
			}
		}

		return Comment(utf8.runes_to_string(comment_runes[:])), true
	}

	return
}
