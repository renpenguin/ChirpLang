package scope

import p "../parser"
import d "./definitions"

// Function defined within the language
InterpretedFunction :: d.InterpretedFunction

// Error returned by external functions in case of an error with the input values
FunctionError :: d.FunctionError
// Holds a pointer to an Odin function
BuiltInFunction :: d.BuiltInFunction

Function :: d.Function

// Gets the function name, regardless of the union type
get_function_name :: proc(function: Function) -> p.NameDefinition {
	switch func in function {
	case InterpretedFunction: return func.name
	case BuiltInFunction:     return func.name
	case:                     panic("Unreachable")
	}
}
