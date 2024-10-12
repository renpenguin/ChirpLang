package format

import t "../tokeniser"
import "core:fmt"
import "core:strings"

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

builtin_keyword_to_string :: proc(keyword: t.BuiltInKeyword) -> string {
	if keyword == .FString do return strings.clone("f")

	formatted := fmt.aprint(keyword)
	defer delete(formatted)
	return strings.to_lower(formatted)
}

bracket_to_rune :: proc(bracket: t.Bracket) -> rune {
	switch bracket {
	case t.Bracket { .Round, .Opening }: return '('
	case t.Bracket { .Round, .Closing }: return ')'
	case t.Bracket { .Square, .Opening }: return '['
	case t.Bracket { .Square, .Closing }: return ']'
	case t.Bracket { .Curly, .Opening }: return '{'
	case t.Bracket { .Curly, .Closing }: return '}'
	}

	panic("Unreachable")
}
