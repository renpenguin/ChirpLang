package libraries

import p "../../parser"
import t "../../tokeniser"
import d "../definitions"
import "core:time"

@(private = "file")
mod_time_sleep :: proc(args: [dynamic]p.Value) -> (return_value := p.None, err := FuncError{ok = true}) {
	if len(args) != 1 do return p.None, FuncError{msg = "Incorrect number of args"}
	delay: f64
	delay, err.ok = args[0].(t.float)
	if !err.ok {err.msg = "Only argument must be float";return}

	time.sleep(time.Duration(delay * f64(time.Second)))

	return
}

@(private)
mod_time :: proc() -> d.Module {
	using p, d
	mod := Module{NameDefinition("time"), new(Scope)}
	append(&mod.scope.functions, BuiltInFunction{NameDefinition("sleep"), mod_time_sleep})

	return mod
}
