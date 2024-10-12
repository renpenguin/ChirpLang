package main

import "core:fmt"
import "core:strings"
import "core:unicode/utf8"
import t "tokeniser"

operator_to_string :: proc(op: t.Operator) -> string {
	switch op {
		case .Add: return "+"
		case .AddAssign: return "+="
		case .Sub: return "-"
		case .SubAssign: return "-="
		case .Mul: return "*"
		case .MulAssign: return "="
		case .Div: return "/"
		case .DivAssign: return "/="
		case .And: return "and"
		case .Or: return "or"
		case .Not: return "!"
		case .NotEqual: return "!="
		case .Assign: return "="
		case .IsEqual: return "=="
		case .GreaterThan: return ">"
		case .GreaterEqual: return ">="
		case .LessThan: return "<"
		case .LessEqual: return "<="
	}

	panic("Unreachable")
}

write_bracket :: proc(
	builder: ^strings.Builder,
	previous_token: t.Token,
	indent: ^int,
	bracket: t.Bracket,
) {
	if bracket.state == .Opening {
		indent^ += 1

		switch bracket.type {
			case .Round: strings.write_rune(builder, '(')
			case .Square: strings.write_rune(builder, '[')
			case .Curly: strings.write_string(builder, " {")
		}
	} else {
		indent^ -= 1
		_, was_new_line := previous_token.(t.NewLineType)
		if was_new_line do strings.pop_rune(builder)

		switch bracket.type {
			case .Round: strings.write_rune(builder, ')')
			case .Square: strings.write_rune(builder,  ']')
			case .Curly: strings.write_rune(builder, '}')
		}
	}
}

tokens_to_string :: proc(tokens: []t.Token) -> string {
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
			strings.write_string(&sb, string(token.(Keyword)))

		case Bracket:
			write_bracket(&sb, previous_token, &indent, token.(Bracket))

		case Literal:
			literal := token.(Literal)
			switch _ in literal {
			case bool:
				strings.write_string(&sb, literal.(bool) ? "true" : "false")
			case string:
				strings.write_rune(&sb, '"')
				strings.write_string(&sb, literal.(string))
				strings.write_rune(&sb, '"')
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
