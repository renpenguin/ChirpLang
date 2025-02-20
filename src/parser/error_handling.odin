package parser

import t "../tokeniser"
import "core:fmt"

// Potential syntax error
SyntaxError :: struct {
	msg:   string,
	// The keyword to blame. Helpful for giving the user more context about the error (should every keyword contain a (line,column) property for errors?)
	found: Maybe(t.Token),
	// Whether the code ran fine actually. When `false`, an error has occured
	ok:    bool,
}

// Ensure that the passed token is a `CustomKeyword`, and return it or an error if it isnt
@(require_results)
@(private)
expect_custom_keyword :: proc(
	token: t.Token,
	error_msg: string,
) -> (
	keyword: t.CustomKeyword,
	err := SyntaxError{ok = true},
) {
	kw, ok := token.(t.Keyword)
	if ok {
		keyword, ok = kw.(t.CustomKeyword)
		if ok do return
	}

	return t.CustomKeyword(""), SyntaxError{msg = error_msg, found = token}
}

// Ensure that the passed tokens match, and return an error if they dont
@(require_results)
@(private)
expect_token :: proc(token, expected_token: t.Token, error_msg: string) -> (err: SyntaxError) {
	return SyntaxError{msg = error_msg, found = token, ok = token == expected_token}
}

// Display an appropriate error message for the passed error, and returns true if an error was found and printed
display_syntax_error :: proc(err: SyntaxError) -> bool {
	if !err.ok {
		if found, ok := err.found.?; ok {
			fmt.eprintln("Syntax error: ", err.msg, ", found ", found, sep = "")
		} else {
			fmt.eprintln("Syntax error: ", err.msg, sep = "")
		}
	}
	return !err.ok
}
