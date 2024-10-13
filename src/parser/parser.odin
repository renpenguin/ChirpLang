package parser

import t "../tokeniser"
import "core:fmt"

// Block of code delimited by `{}`
Block :: distinct [dynamic]Statement

parse :: proc(tokens: t.TokenStream) -> (instructions: Block, err: ParseError) {
	using t
	err = ParseError {
		ok = true,
	}

	for i := 0; i < len(tokens); i += 1 {
		if t.is_new_line(tokens[i]) do continue

		// Import
		import_statement: Maybe(Import)
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

		// Expression (catch-all for anything we may have missed)
		expr: Expression
		expr, err = capture_expression(tokens, &i)
		if !err.ok do return
		append(&instructions, Statement(expr))
	}

	return
}
