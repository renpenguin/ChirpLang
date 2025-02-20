package execute

import p "../parser"
import s "../scope"
import f "../formatter"
import t "../tokeniser"
import "core:fmt"

TypeError :: struct {
	msg:            string,
	expected, found: Maybe(p.ValueType),
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
	if !is_err do return

	fmt.eprint("Runtime error: ")
	switch e in err {
	case TypeError:
		fmt.eprint("Type error -", e.msg)
		if _, ok := e.expected.?; 	ok do fmt.eprint(", expected", e.expected)
		if _, ok := e.found.?; 	ok do fmt.eprint(", found", e.found)
		if _, ok := e.op.?; 		ok do fmt.eprint(" (using operator", e.op, "\b)")
		fmt.eprintln()
	case StackOverflow:
		fmt.eprintfln("Stack overflow error calling %s()", e)
	case s.FunctionError:
		fmt.eprintfln("Function error when calling %s()... %s", f.name_ref_to_string(e.func_name), e.msg)
	case NoError:
		panic("Unreachable")
	}
	return
}
