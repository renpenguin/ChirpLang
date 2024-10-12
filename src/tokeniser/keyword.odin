package tokeniser

import "core:unicode"
import "core:unicode/utf8"

BuiltInKeyword :: enum {
	Import,
	Func,
	Var,
	If,
	Else,
	For,
	While,
	Forever,
	Break,
	Continue,
	Return,
	FString,
}

CustomKeyword :: distinct string // Reference or definition of variables/parameters/functions

Keyword :: distinct union {
	BuiltInKeyword,
	CustomKeyword,
}

// Parses and returns a keyword from the string
try_parse_keyword :: proc(input_chars: []rune, char_index: ^int) -> (keyword: Keyword, ok: bool) {
	c := input_chars[char_index^]
	if !unicode.is_letter(c) do return nil, false

	keyword_runes: [dynamic]rune
	defer delete(keyword_runes)

	append(&keyword_runes, c)

	for j := char_index^ + 1; j < len(input_chars); j += 1 {
		c := input_chars[j]
		if unicode.is_letter(c) || unicode.is_number(c) || c == '_' || c == ':' {
			append(&keyword_runes, c)
			if c == '=' {
			}
			char_index^ += 1
		} else {
			break
		}
	}

	custom_keyword := CustomKeyword(utf8.runes_to_string(keyword_runes[:]))

	if builtin_keyword, ok := try_match_to_builtin_keyword(custom_keyword); ok {
		delete(string(custom_keyword))
		return Keyword(builtin_keyword), true
	} else {
		return Keyword(custom_keyword), true
	}
}

// Attempts to map the input `CustomKeyword` to a `BuiltInKeyword`
@(private)
try_match_to_builtin_keyword :: proc(
	custom_keyword: CustomKeyword,
) -> (
	keyword: BuiltInKeyword,
	ok: bool,
) {
	ok = true

	switch custom_keyword {
	case "import": keyword = .Import
	case "func": keyword = .Func
	case "var": keyword = .Var
	case "if": keyword = .If
	case "else": keyword = .Else
	case "for": keyword = .For
	case "while": keyword = .While
	case "forever": keyword = .Forever
	case "break": keyword = .Break
	case "continue": keyword = .Continue
	case "return": keyword = .Return
	case "f": keyword = .FString
	case: ok = false
	}

	return
}
