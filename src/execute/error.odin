package execute

import p "../parser"
import s "../scope"
import t "../tokeniser"

TypeError :: struct {
	msg:            string,
	value1, value2: Maybe(p.ValueType),
	op:             Maybe(t.ArithmeticOperator),
	ok:             bool,
}

NoError :: struct {}
NoErrorUnit :: NoError{}

RuntimeError :: union #no_nil {
	TypeError,
	s.BuiltInFunctionError,
	NoError,
}

is_runtime_error_ok :: proc(err: RuntimeError) -> bool {
	switch _ in err {
	case TypeError:
		return err.(TypeError).ok
	case s.BuiltInFunctionError:
		return err.(s.BuiltInFunctionError).ok
	case NoError:
		return true
	case:
		panic("Unreachable")
	}
}
