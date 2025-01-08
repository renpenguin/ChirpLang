package tokeniser

import "core:unicode"
import "core:unicode/utf8"

BuiltInKeyword :: enum {
	Import,
	Func,
	Var,
	Let,
	If, // NYI
	Else, // NYI
	For, // NYI
	While, // NYI
	Forever,
	Break, // NYI
	Continue, // NYI
	ReturnType, // ->
	Return,
	FString, // NYI
}

TypeKeyword :: enum {
	Int,
	Float,
	String,
	Bool,
	None,
	// Array,
	// Struct,
}

// Reference or definition of variables/parameters/functions. Parts are separated by `:`. Each part begins with a letter, and can contain letters, digits or `_`
CustomKeyword :: distinct string

Keyword :: distinct union {
	TypeKeyword,
	BuiltInKeyword,
	CustomKeyword,
}

// Parses and returns a keyword from the string
try_parse_keyword :: proc(input_chars: []rune, char_index: ^int) -> (keyword: Keyword, ok := true) {
	c := input_chars[char_index^]
	if !unicode.is_letter(c) do return nil, false

	keyword_runes: [dynamic]rune
	defer delete(keyword_runes)

	append(&keyword_runes, c)

	last_c := c
	for j := char_index^ + 1; j < len(input_chars); j += 1 {
		c := input_chars[j]
		if unicode.is_letter(c) || unicode.is_number(c) || c == '_' || c == ':' {
			if last_c == ':' && !unicode.is_letter(c) {
				panic("all keywords should begin with a letter, not a digit, _ or :")
			}
			append(&keyword_runes, c)
			last_c = c
			char_index^ += 1
		} else {
			break
		}
	}

	custom_keyword := CustomKeyword(utf8.runes_to_string(keyword_runes[:]))

	keyword = try_match_to_builtin_keyword(custom_keyword)
	if _, ok := keyword.(CustomKeyword); !ok do delete(string(custom_keyword))

	return
}

// Attempts to map the input `CustomKeyword` to a `BuiltInKeyword` or `ValueType`. If unsuccessful, returns the original `CustomKeyword`
@(private = "file")
try_match_to_builtin_keyword :: proc(custom_keyword: CustomKeyword) -> Keyword {
	switch custom_keyword {
	case "import": 	 return .Import
	case "func": 	 return .Func
	case "var": 	 return .Var
	case "let": 	 return .Let
	case "if": 		 return .If
	case "else": 	 return .Else
	case "for": 	 return .For
	case "while": 	 return .While
	case "forever":  return .Forever
	case "break": 	 return .Break
	case "continue": return .Continue
	case "return": 	 return .Return

	case "f": 		 return .FString

	// Types
	case "int": 	 return .Int
	case "float": 	 return .Float
	case "string": 	 return .String
	case "bool": 	 return .Bool
	case "None": 	 return .None

	case: return custom_keyword
	}
}
