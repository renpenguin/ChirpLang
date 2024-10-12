package main

import "core:fmt"
import "core:strings"
import "core:unicode"
import "core:unicode/utf8"

MAX_ALLOWED_NEWLINES :: 2

Operator :: enum {
	Add, // +
	AddAssign, // +=
	Sub, // -
	SubAssign, // -=
	Mul, // *
	MulAssign, //*=
	Div, // /
	DivAssign, // /=
	And, // and
	Or, // or
	Not, // !
	NotEqual, // !=
	Assign, // =
	IsEqual, // ==
	GreaterThan, // >
	GreaterEqual, // >=
	LessThan, // <
	LessEqual, // <=
}

// Attempts to match the present runes to an operator, checking for a trailing `=`
try_match_to_assignable_operator :: proc(
	input_chars: []rune,
	i: ^int,
) -> (
	found_operator: Operator,
	ok: bool,
) {
	operators_with_possible_trailing_equals := map[rune]struct {
		default_op, assign_op: Operator,
	} {
		'=' = {.Assign, .IsEqual},
		'+' = {.Add, .AddAssign},
		'-' = {.Sub, .SubAssign},
		'*' = {.Mul, .MulAssign},
		'/' = {.Div, .DivAssign},
		'!' = {.Not, .NotEqual},
		'>' = {.GreaterThan, .GreaterEqual},
		'<' = {.LessThan, .LessEqual},
	}

	for key, value in operators_with_possible_trailing_equals {
		if input_chars[i^] == key {
			ok = true
			if input_chars[i^ + 1] == '=' {
				i^ += 1
				found_operator = value.assign_op
			} else {
				found_operator = value.default_op
			}
			break
		}
	}

	return
}

Keyword :: distinct string // TODO: expand into a union of enum of built in keywords like `for` and `forever`, and for accessing functions/variables

Bracket :: struct {
	type:  enum {
		Round, // Used for calling/defining functions, order of operations,
		Square, // Used to define and access arrays
		Curly, // Used for function/if/loop scope and struct/enum definitions
	},
	state: enum {
		Opening,
		Closing,
	},
}

Literal :: union #no_nil {
	string,
	int,
}

CommaType :: struct {} // unique zero-sided type
Comma :: CommaType{} // shorthand to avoid having to add braces every time i want to define a comma

NewLineType :: struct { count: uint } // unique zero-sided type
NewLine :: NewLineType{ 1 } // shorthand to avoid having to add braces every time i want to define a comma

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
tokenise :: proc(input: string) -> [dynamic]Token {
	tokens: [dynamic]Token

	input_chars := utf8.string_to_runes(input)
	for i := 0; i < len(input_chars); i += 1 {
		c := input_chars[i]

		// Ignore whitespace
		if strings.is_space(c) && c != '\n' do continue

		// Handle new lines
		if c == '\n' || c == ';' {
			append_new_line(&tokens)
		} else if len(tokens) > 0 {
			// If immediately after { and not newline, add a newline first
			previous_token, was_bracket := tokens[len(tokens) - 1].(Bracket)
			if was_bracket {
				if (previous_token == Bracket{.Curly, .Opening}) {
					append_new_line(&tokens)
				}
			}
		}


		// Keywords
		if unicode.is_letter(c) {
			keyword_runes: [dynamic]rune
			defer delete(keyword_runes)

			append(&keyword_runes, c)

			for j := i + 1; j < len(input_chars); j += 1 {
				c := input_chars[j]
				if unicode.is_letter(c) || unicode.is_number(c) || c == '_' || c == ':' {
					append(&keyword_runes, c)
					if c == '=' {
					}
					i += 1
				} else {
					break
				}
			}

			append(&tokens, Keyword(utf8.runes_to_string(keyword_runes[:])))
			continue
		}

		// String literals
		if c == '"' || c == '\'' {
			string_runes: [dynamic]rune
			defer delete(string_runes)

			for j := i + 1; j < len(input_chars); j += 1 {
				c := input_chars[j]
				i += 1
				if c == '"' || c == '\'' { 	// TODO: handle \" and \'
					break
				} else {
					append(&string_runes, c)
				}
			}

			append(&tokens, Literal(utf8.runes_to_string(string_runes[:])))
			continue
		}

		// Number literals
		if unicode.is_number(c) {
			number_literal := int(c) - 48

			for j := i + 1; j < len(input_chars); j += 1 {
				c := input_chars[j]
				if unicode.is_number(c) {
					number_literal *= 10
					number_literal += (int(c) - 48) // Unicode offset
					i += 1
				} else {
					break
				}
			}

			append(&tokens, Literal(number_literal))
			continue
		}

		op, ok := try_match_to_assignable_operator(input_chars, &i)
		if ok {
			append(&tokens, op)
			continue
		}

		// Brackets and comma
		switch c {
		case ',':
			append(&tokens, Comma)

		// Brackets
		case '(': append(&tokens, Bracket{.Round, .Opening})
		case ')': append(&tokens, Bracket{.Round, .Closing})
		case '[': append(&tokens, Bracket{.Square, .Opening})
		case ']': append(&tokens, Bracket{.Square, .Closing})
		case '{':
			append(&tokens, Bracket{.Curly, .Opening})
		case '}':
			// If no newline before }, add a newline first
			_, was_bracket := tokens[len(tokens) - 1].(NewLineType)
			if !was_bracket {
				append_new_line(&tokens)
			}
			append(&tokens, Bracket{.Curly, .Closing})

		case:
			fmt.println("unexpected token!")
		}
	}

	return tokens
}
