package parser

import t "../tokeniser"
import "core:fmt"

// Parses the `TokenStream` into a `Block`. If an error occurs, it is returned via the `err` field which should be handled. Consumes the `TokenStream`
parse :: proc(tokens: t.TokenStream) -> (instructions: Block, err := SyntaxError{ok = true}) {
	using t

	for i := 0; i < len(tokens); i += 1 {
		if is_new_line(tokens[i]) do continue

		// Import statement
		import_statement: Maybe(ImportStatement)
		import_statement, err = try_match_import(tokens, &i)
		if !err.ok do return
		if statement, ok := import_statement.?; ok {
			append(&instructions, statement)
			continue
		}

		// Function
		func_def: Maybe(FunctionDefinition)
		func_def, err = try_match_func_definition(tokens, &i)
		if !err.ok do return
		if statement, ok := func_def.?; ok {
			append(&instructions, statement)
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
		var_def: Maybe(VariableDefinition)
		var_def, err = try_match_var_definition(tokens, &i)
		if !err.ok do return
		if statement, ok := var_def.?; ok {
			append(&instructions, statement)
			continue
		}

		// Variable assignment
		var_assignment: Maybe(VariableAssignment)
		var_assignment, err = try_match_var_assignment(tokens, &i)
		if !err.ok do return
		if statement, ok := var_assignment.?; ok {
			append(&instructions, statement)
			continue
		}

		// Return
		if tokens[i] == Token(Keyword(.Return)) {
			return_expr: Expression

			i += 1
			return_expr, err = capture_expression(tokens, &i)
			if !err.ok do return

			append(&instructions, Return(return_expr))
			continue
		}

		// Expression (catch-all for anything we may have missed)
		expr: Expression
		expr, err = capture_expression(tokens, &i)
		if !err.ok do return
		append(&instructions, Statement(expr))
	}
	delete(tokens)

	return
}
