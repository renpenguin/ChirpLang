package formatter

import t "../tokeniser"
import "core:fmt"
import "core:strings"
import "core:unicode/utf8"

@(private)
write_bracket :: proc(
	sb: ^strings.Builder,
	previous_token: t.Token,
	indent: ^int,
	bracket: t.Bracket,
) {
	if bracket.state == .Opening {
		indent^ += 1

		if bracket.type == .Curly {
			strings.write_rune(sb, ' ')
		}
	} else {
		indent^ -= 1
		if t.is_new_line(previous_token) do strings.pop_rune(sb)
	}

	strings.write_rune(sb, bracket_to_rune(bracket))
}

// Parses the token stream back into a human-readable string
format :: proc(tokens: t.TokenStream) -> string {
	using t
	sb := strings.builder_make()

	previous_token: Token
	indent := 0
	for token in tokens {
		switch _ in token {
		case Operator:
			strings.write_rune(&sb, ' ')
			strings.write_string(&sb, operator_to_string(token.(Operator)))
			strings.write_rune(&sb, ' ')

		case Keyword:
			_, was_keyword := previous_token.(Keyword)
			if was_keyword do strings.write_rune(&sb, ' ')

			keyword := token.(Keyword)
			switch _ in keyword {
			case BuiltInKeyword:
				builtin_keyword := builtin_keyword_to_string(keyword.(BuiltInKeyword))
				strings.write_string(&sb, builtin_keyword)
				defer delete(builtin_keyword)
			case CustomKeyword:
				strings.write_string(&sb, string(keyword.(CustomKeyword)))
			}

		case Bracket:
			write_bracket(&sb, previous_token, &indent, token.(Bracket))

		case Literal:
			literal := token.(Literal)
			switch _ in literal {
			case bool:
				strings.write_string(&sb, literal.(bool) ? "true" : "false")
			case string:
				strings.write_quoted_string(&sb, literal.(string))
			case int:
				strings.write_int(&sb, literal.(int))
			case float:
				strings.write_f64(&sb, literal.(float), 'g')
			}

		case CommaType:
			strings.write_string(&sb, ", ")

		case NewLineType:
			for i: uint = 0; i < token.(NewLineType).count; i += 1 {
				strings.write_rune(&sb, '\n')
			}
			for i := 0; i < indent; i += 1 {
				strings.write_rune(&sb, '\t')
			}
		}

		previous_token = token
	}

	return strings.to_string(sb)
}
