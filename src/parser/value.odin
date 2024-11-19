package parser

import t "../tokeniser"

NoneType :: struct {}
None :: NoneType{}

ValueType :: enum {
	Int,
	Float,
	String,
	Bool,
	None,
	// Array,
	// Struct,
}
Value :: union #no_nil {
	int,
	t.float,
	string,
	bool,
	NoneType,
}

literal_to_value :: proc(literal: t.Literal) -> Value {
	switch _ in literal {
	case int:
		return Value(literal.(int))
	case t.float:
		return Value(literal.(t.float))
	case string:
		return Value(literal.(string))
	case bool:
		return Value(literal.(bool))
	case:
		panic("Unreachable")
	}
}

get_value_type :: proc(value: Value) -> ValueType {
	switch _ in value {
	case int:
		return .Int
	case t.float:
		return .Float
	case string:
		return .String
	case bool:
		return .Bool
	case NoneType:
		return .None
	case:
		panic("Unreachable")
	}
}

// TODO: ValueType should be a valid token
// expect_value_type :: proc(
// 	token: t.Token,
// 	not_keyword_error_msg: string,
// ) -> (
// 	name_def: ValueType,
// 	err: SyntaxError,
// )
