package execute_defs

import p "../../parser"

Rc :: struct {
	value:      p.Value,
	references: int,
}

// A value at runtime can either be a constant `parser.Value`, or an `Rc` containing the same parser.Value
RTValue :: union #no_nil {
	p.Value,
	^Rc,
}
