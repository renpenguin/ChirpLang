package parser

import t "../tokeniser"
import "core:fmt"
import "core:strings"

// Name definition. Does not have `:` anywhere
NameDefinition :: distinct string

NameReference :: struct {
	path: Maybe([dynamic]NameDefinition),
	// The actual name being accessed. Begins with a letter, can contain letters, digits or an `_`
	name:  NameDefinition,
}

expect_name_def :: proc(
	token: t.Token,
	not_keyword_error_msg: string,
) -> (
	name_def: NameDefinition,
	err: SyntaxError,
) {
	keyword: t.CustomKeyword
	keyword, err = expect_custom_keyword(token, not_keyword_error_msg)
	if strings.contains_rune(string(keyword), ':') {
		return NameDefinition(
			"",
		), SyntaxError{error_msg = "Expected name definition (no path reference `:`)", found = t.Token(t.Keyword(keyword))}
	} else {
		return NameDefinition(keyword), SyntaxError{ok = true}
	}
}

// Converts the keyword to a `NameReference`. Consumes the keyword
keyword_to_name_ref :: proc(keyword: t.CustomKeyword) -> NameReference {
	keyword := string(keyword)
	defer delete(keyword)

	if !strings.contains_rune(string(keyword), ':') {
		name := NameDefinition(strings.clone(keyword))
		return NameReference{nil, name}
	}

	parts, err := strings.split(string(keyword), ":")
	defer delete(parts)
	if err != nil do return NameReference{name = NameDefinition(keyword)}

	name := NameDefinition(strings.clone(parts[len(parts) - 1]))

	scope: [dynamic]NameDefinition
	for part, i in parts[:len(parts) - 1] {
		append(&scope, NameDefinition(strings.clone(part)))
	}

	return NameReference{scope, name}
}

destroy_name_ref :: proc(declared_name: NameReference) {
	if path, ok := declared_name.path.?; ok {
		for path_step in path {
			delete(string(path_step))
		}
		delete(path)
	}
	delete(string(declared_name.name))
}
