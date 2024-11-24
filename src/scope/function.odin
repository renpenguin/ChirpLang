package scope

import p "../parser"
import d "./definitions"

// Function defined within the language
InterpretedFunction :: d.InterpretedFunction

// Error returned by external functions in case of an error with the input values
BuiltInFunctionError :: d.BuiltInFunctionError
// Holds a pointer to an Odin function
BuiltInFunction :: d.BuiltInFunction

Function :: d.Function

// Gets the function name, regardless of the union type
get_function_name :: proc(func: Function) -> p.NameDefinition {
	switch _ in func {
	case InterpretedFunction:
		return func.(InterpretedFunction).name
	case BuiltInFunction:
		return func.(BuiltInFunction).name
	case:
		panic("Unreachable")
	}
}
