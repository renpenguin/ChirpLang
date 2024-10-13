package parser

import t "../tokeniser"
import "core:fmt"

// Brings libraries or functions into scope. Expected pattern `import $library$, ...;`
Import :: distinct [dynamic]t.CustomKeyword
// Defines a new variable in the current scope. Expected pattern `var $name$ = $expr$;`
VariableDefinition :: struct {
	name: t.CustomKeyword,
	expr: Expression,
}
AssignmentOperator :: enum {
	Set        = int(t.Operator.Assign),
	Increment  = int(t.Operator.AddAssign),
	Decrement  = int(t.Operator.SubAssign),
	MultiplyBy = int(t.Operator.MulAssign),
	DivideBy   = int(t.Operator.DivAssign),
}
// Operation that either is or ends with `=`. Expected pattern `$name$ $operator$ $expr$;`
VariableAssignment :: struct {
	target_variable: t.CustomKeyword,
	operator:       AssignmentOperator,
	expr:            Expression,
}
// Defines a function. Expected pattern `func $name$($name$, ...) $block$`
FunctionDefinition :: struct {
	name:  t.CustomKeyword,
	args:  [dynamic]t.CustomKeyword,
	block: Block,
}
// Calls a function with the given name and passes a list of arguments. Expected pattern `$name$($expr$, ...)``
FunctionCall :: struct {
	name: t.CustomKeyword,
	args: [dynamic]Expression,
}
// Executes a block until `Break` is triggered
Forever :: struct {
	block: Block,
}

//
Statement :: union {
	Import,
	VariableDefinition,
	VariableAssignment,
	FunctionDefinition,
	Forever,
	Expression,
}

// Block of code delimited by `()` that evaluates to one value
Expression :: distinct t.TokenStream // TODO: make this its own union (yes, this works)
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
		if _, ok := tokens[i].(t.NewLineType); ok do continue

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
				if _, ok := tokens[i].(t.NewLineType); ok do break
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
				err = expect_token(
					tokens[i],
					Token(Comma),
					"Expected ) or comma after function argument",
				)
			}

			i += 1
			func_def.block, err = capture_block(tokens, &i)
			if !err.ok do return

			append(&instructions, func_def)
			continue
		}

		// Forever
		if tokens[i] == Token(Keyword(BuiltInKeyword.Forever)) {
			forever: Forever

			i += 1
			forever.block, err = capture_block(tokens, &i)
			if !err.ok do return

			append(&instructions, forever)
			continue
		}

		// Variable definition
		if tokens[i] == Token(Keyword(BuiltInKeyword.Var)) {
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
				Token(Operator.Assign),
				"Expected `=` after variable name in variable definition",
			)
			if !err.ok do return

			i += 1
			var_def.expr = capture_expression(tokens, &i)

			append(&instructions, var_def)
			continue
		}

		// Assignment
		if var_name, ok := tokens[i].(t.Keyword).(t.CustomKeyword); ok {
			if op, ok := tokens[i + 1].(t.Operator); ok {
				#partial switch op {
				case .Assign, .AddAssign, .SubAssign, .MulAssign, .DivAssign:
					operator := AssignmentOperator(op)
					fmt.println(operator == nil)
					fmt.println("using operator", operator, "on", var_name)
					var_assignment := VariableAssignment {
						target_variable = var_name,
						operator = AssignmentOperator(int(op)),
					}

					i += 2
					var_assignment.expr = capture_expression(tokens, &i)

					append(&instructions, var_assignment)
					continue
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
		if _, ok := tokens[token_index^].(t.NewLineType); ok do break

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
