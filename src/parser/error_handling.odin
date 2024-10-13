package parser

import t "../tokeniser"

// Potential error returned by `parser` library functions
ParseError :: struct {
	error_msg: string,
	found:     Maybe(t.Token),
	ok:        bool,
}

// Ensure that the passed token is a `CustomKeyword`, and return it or an error if it isnt
@(require_results)
expect_custom_keyword :: proc(
	token: t.Token,
	error_msg: string,
) -> (
	keyword: t.CustomKeyword,
	err: ParseError,
) {
	kw, kw_ok := token.(t.Keyword)
	if kw_ok {
		ckw, ckw_ok := kw.(t.CustomKeyword)
		if ckw_ok {
			return ckw, ParseError{ok = true}
		}
	}

	return t.CustomKeyword(""), ParseError{error_msg = error_msg, found = token}
}

// Ensure that the passed tokens match, and return an error if they dont
@(require_results)
expect_token :: proc(token, expected_token: t.Token, error_msg: string) -> (err: ParseError) {
	return ParseError{error_msg = error_msg, found = token, ok = token == expected_token}
}
