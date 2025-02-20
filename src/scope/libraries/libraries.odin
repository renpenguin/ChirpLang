package libraries

import p "../../parser"
import d "../definitions"

@(private)
FuncError :: d.FunctionError

try_access_library :: proc(lib_ref: p.NameReference) -> (lib: d.Module, ok: bool) {
	if lib_ref.path != nil do return // TODO: import lines shouldn't try to have paths for now

	switch lib_ref.name {
	case "time":
		return mod_time(), true
	case "random":
		return mod_random(), true
	case "math":
		return mod_math(), true
	case:
		return
	}
}
