package parser

import t "../tokeniser"
import "core:fmt"

// Block of code delimited by `{}`
Block :: distinct [dynamic]Statement

ParseError :: struct {
	error_msg: string,
	found:     t.Token,
	ok:        bool,
}

parse :: proc(tokens: t.TokenStream) -> (instructions: Block, err: ParseError) {
	using t
	err = ParseError {
		ok = true,
	}

	for i := 0; i < len(tokens); i += 1 {
		if t.is_new_line(tokens[i]) do continue

		// Import
		if tokens[i] == Token(Keyword(BuiltInKeyword.Import)) {
			import_statement: Import

			for {
				i += 1
				keyword: CustomKeyword
				keyword, err = expect_custom_keyword(
					tokens[i],
					"Expected library reference in import statement",
				)
				if !err.ok do return

				append(&import_statement, keyword)

				i += 1
				if t.is_new_line(tokens[i]) do break
				err = expect_token(
					tokens[i],
					Comma,
					"Expected newline or comma after library reference in import statement",
				)
				if !err.ok do return
			}

			append(&instructions, import_statement)
			continue
		}

		// Function
		if tokens[i] == Token(Keyword(BuiltInKeyword.Func)) {
			func_def: FunctionDefinition

			i += 1
			func_def.name, err = expect_custom_keyword(
				tokens[i],
				"Expected function name in function definition",
			)
			if !err.ok do return

			i += 1
			err = expect_token(
				tokens[i],
				Token(Bracket{.Round, .Opening}),
				"Expected ( in function",
			)
			if !err.ok do return

			for {
				i += 1
				if tokens[i] == Token(Bracket{.Round, .Closing}) do break
				arg_name: t.CustomKeyword
				arg_name, err = expect_custom_keyword(
					tokens[i],
					"Expected argument name in function definition",
				)
				if !err.ok do return

				append(&func_def.args, arg_name)

				if tokens[i] == Token(Bracket{.Round, .Closing}) do break
				err = expect_token(tokens[i], Comma, "Expected ) or comma after function argument")
			}

			i += 1
			func_def.block, err = capture_block(tokens, &i)
			if !err.ok do return

			append(&instructions, func_def)
			continue
		}

		// Forever
		if tokens[i] == Token(Keyword(.Forever)) {
			forever: Forever

			i += 1
			forever.block, err = capture_block(tokens, &i)
			if !err.ok do return

			append(&instructions, forever)
			continue
		}

		// Variable definition
		if tokens[i] == Token(Keyword(.Var)) {
			var_def: VariableDefinition

			i += 1
			var_def.name, err = expect_custom_keyword(
				tokens[i],
				"Expected variable name after `var` in variable definition",
			)
			if !err.ok do return

			i += 1
			err = expect_token(
				tokens[i],
				Token(Operator(.Assign)),
				"Expected `=` after variable name in variable definition",
			)
			if !err.ok do return

			i += 1
			var_def.expr = capture_expression(tokens, &i)

			append(&instructions, var_def)
			continue
		}

		// Assignment
		if keyword, ok := tokens[i].(t.Keyword); ok {
			if var_name, ok := keyword.(t.CustomKeyword); ok {
				if op, ok := tokens[i + 1].(t.Operator); ok {
					if ass_op, ok := op.(t.AssignmentOperator); ok {
						i += 2 // skip name and operator
						var_assignment := VariableAssignment {
							target_var = var_name,
							operator   = ass_op,
							expr       = capture_expression(tokens, &i),
						}
						append(&instructions, var_assignment)
						continue
					}
				}
			}
		}

		// Expression (catch-all for anything we may have missed)
		append(&instructions, Statement(capture_expression(tokens, &i)))
	}

	return
}

// Captures all `Token`s until a newline into an `Expression`
capture_expression :: proc(tokens: t.TokenStream, token_index: ^int) -> (expr: Expression) {
	for { 	// TODO: make sure the expression isnt complete gibberish (keep brackets, function calls etc. in mind)
		if t.is_new_line(tokens[token_index^]) do break

		append(&expr, tokens[token_index^])
		token_index^ += 1
	}

	return
}

capture_block :: proc(
	tokens: t.TokenStream,
	token_index: ^int,
) -> (
	block: Block,
	err: ParseError,
) {
	err = expect_token(
		tokens[token_index^],
		t.Bracket{.Curly, .Opening},
		"Expected scope to begin with {",
	)
	if !err.ok do return

	captured_tokens: t.TokenStream
	defer delete(captured_tokens)
	bracket_depth := 1

	for bracket_depth > 0 {
		token_index^ += 1
		token := tokens[token_index^]
		if token == t.Token(t.Bracket{.Curly, .Opening}) do bracket_depth += 1
		else if token == t.Token(t.Bracket{.Curly, .Closing}) do bracket_depth -= 1

		append(&captured_tokens, token)
	}
	pop(&captured_tokens) // Remove last }

	return parse(captured_tokens)
}

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

@(require_results)
expect_token :: proc(token, expected_token: t.Token, error_msg: string) -> (err: ParseError) {
	return ParseError{error_msg = error_msg, found = token, ok = token == expected_token}
}
