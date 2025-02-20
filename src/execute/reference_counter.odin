package execute

import p "../parser"
import d "definitions"
import "core:fmt"

Rc :: d.Rc
RTValue :: d.RTValue

RTNone: RTValue : p.None

// Create a new reference counted runtime value
new_rc :: proc(value: p.Value) -> RTValue {
	rc := new(Rc)
	rc.value = value
	rc.references = 1
	return rc
}

get_value :: proc(value: RTValue) -> p.Value {
	switch v in value {
	case p.Value: return v
	case ^Rc:     return v.value
	case:         panic("Unreachable")
	}
}

get_value_type :: proc(value: RTValue) -> p.ValueType {
	switch v in value {
	case p.Value: return p.get_value_type(v)
	case ^Rc:     return p.get_value_type(v.value)
	case:         panic("Unreachable")
	}
}

// Passthrough function for `RTValue` that increments `^Rc`'s `references` property.
// This should not be used on its own, rather in line with whatever is getting the new reference, per convention
@(require_results)
inc_rc :: proc(value: RTValue) -> RTValue {
	if rc, is_rc := value.(^Rc); is_rc do rc.references += 1
	return value
}

free_value :: proc(value: RTValue) {
	rc, ok := value.(^Rc)
	if !ok do return // Constant literals are freed by `parser.destroy_block`

	rc.references -= 1
	if rc.references <= 0 {
		switch val in rc.value {
			case int:
			case f64:
			case string:
				delete(val)
			case bool:
			case p.NoneType:
		}
		free(rc)
	}
}
