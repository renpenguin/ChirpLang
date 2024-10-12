package format

import t "../tokeniser"

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
