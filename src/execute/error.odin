package execute

import p "../parser"
import s "../scope"
import t "../tokeniser"

TypeError :: struct {
	msg:    string,
	values: Maybe([dynamic]p.ValueType),
	op:     Maybe(t.ArithmeticOperator),
	ok:     bool,
}

NoError :: struct {}
NoErrorUnit :: NoError{}

RuntimeError :: union #no_nil {
	TypeError,
	s.BuiltInFunctionError,
	NoError,
}
