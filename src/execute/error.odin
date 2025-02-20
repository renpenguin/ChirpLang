package execute

import p "../parser"
import s "../scope"
import f "../formatter"
import t "../tokeniser"
import "core:fmt"

TypeError :: struct {
	msg:            string,
	value1, value2: Maybe(p.ValueType),
	op:             Maybe(t.ArithmeticOperator),
	ok:             bool,
}

NoError :: struct {}
NoErrorUnit :: NoError{}

StackOverflow :: p.NameDefinition

RuntimeError :: union #no_nil {
	TypeError,
	StackOverflow,
	s.FunctionError,
	NoError,
}

is_runtime_error_ok :: proc(err: RuntimeError) -> bool {
	switch e in err {
	case TypeError:
		return e.ok
	case StackOverflow:
		return e == ""
	case s.FunctionError:
		return e.ok
	case NoError:
		return true
	case:
		panic("Unreachable")
	}
}

// Display an appropriate error message for the passed error, and returns true if an error was found and printed
display_runtime_error :: proc(err: RuntimeError) -> (is_err: bool) {
	is_err = !is_runtime_error_ok(err)
	if is_err {
		fmt.eprint("Runtime error: ")
		switch e in err {
		case TypeError:
			fmt.eprintln("Type error -", e.msg, e.value1, e.op, e.value2)
		case StackOverflow:
			fmt.eprintfln("Stack overflow error calling %s()", e)
		case s.FunctionError:
			fmt.eprintfln("Function error when calling %s()... %s", f.name_ref_to_string(e.func_name), e.msg)
		case NoError:
			panic("Unreachable")
		}
	}
	return is_err
}
