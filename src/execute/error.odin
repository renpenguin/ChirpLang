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
	switch _ in err {
	case TypeError:
		return err.(TypeError).ok
	case StackOverflow:
		return err.(StackOverflow) == ""
	case s.FunctionError:
		return err.(s.FunctionError).ok
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
		switch _ in err {
		case TypeError:
			type_err := err.(TypeError)
			fmt.eprintln("Type error -", type_err.msg, type_err.value1, type_err.op, type_err.value2)
		case StackOverflow:
			fmt.eprintfln("Stack overflow error calling %s()", err.(StackOverflow))
		case s.FunctionError:
			fmt.eprintfln("Function error when calling %s()... %s", f.name_ref_to_string(err.(s.FunctionError).func_name), err.(s.FunctionError).msg)
		case NoError:
			panic("Unreachable")
		}
	}
	return is_err
}
