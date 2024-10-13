package parser

import t "../tokeniser"

// Brings libraries or functions into scope. Expected pattern `import $library$, ...;`
Import :: distinct [dynamic]t.CustomKeyword

// Defines a new variable in the current scope. Expected pattern `var $name$ = $expr$;`
VariableDefinition :: struct {
	name: t.CustomKeyword,
	expr: Expression,
}

// Operation that either is or ends with `=`. Expected pattern `$name$ $operator$ $expr$;`
VariableAssignment :: struct {
	target_var: t.CustomKeyword,
	operator:   t.AssignmentOperator,
	expr:       Expression,
}

// Defines a function. Expected pattern `func $name$($name$, ...) $block$`
FunctionDefinition :: struct {
	name:  t.CustomKeyword,
	args:  [dynamic]t.CustomKeyword,
	block: Block,
}

// Executes a block until `Break` is triggered. Expected patten `forever $block$`
Forever :: struct {
	block: Block,
}

Statement :: union {
	Import,
	VariableDefinition,
	VariableAssignment,
	FunctionDefinition,
	Forever,
	Expression,
}

// Captures a block of statements surrounded by {}. `token_index` should be the index of the first {
@(private)
capture_block :: proc(
	tokens: t.TokenStream,
	token_index: ^int,
) -> (
	block: Block,
	err: ParseError,
) {
	using t
	err = expect_token(
		tokens[token_index^],
		Bracket{.Curly, .Opening},
		"Expected scope to begin with {",
	)
	if !err.ok do return

	captured_tokens: TokenStream // Deleted by `parse()`
	bracket_depth := 1

	for bracket_depth > 0 {
		token_index^ += 1
		token := tokens[token_index^]
		if token == Token(Bracket{.Curly, .Opening}) do bracket_depth += 1
		else if token == Token(Bracket{.Curly, .Closing}) do bracket_depth -= 1

		append(&captured_tokens, token)
	}
	pop(&captured_tokens) // Remove last }

	return parse(captured_tokens)
}

// Try to match an `Import` statement under the cursor
@(private)
try_match_import :: proc(
	tokens: t.TokenStream,
	char_index: ^int,
) -> (
	import_statement: Maybe(Import),
	err := ParseError{ok = true},
) {
	using t
	if tokens[char_index^] != Token(Keyword(.Import)) do return
	import_statement = Import{}

	for {
		char_index^ += 1
		keyword: CustomKeyword
		keyword, err = expect_custom_keyword(
			tokens[char_index^],
			"Expected library reference in import statement",
		)
		if !err.ok do return

		append(&import_statement.?, keyword)

		char_index^ += 1
		if is_new_line(tokens[char_index^]) do break
		err = expect_token(
			tokens[char_index^],
			Comma,
			"Expected newline or comma after library reference in import statement",
		)
		if !err.ok do return
	}

	return
}

// Try to match a `FunctionDefinition` statement under the cursor
@(private)
try_match_func_definition :: proc(
	tokens: t.TokenStream,
	char_index: ^int,
) -> (
	func_definition: Maybe(FunctionDefinition),
	err := ParseError{ok = true},
) {
	using t
	if tokens[char_index^] != Token(Keyword(.Func)) do return
	func_def: FunctionDefinition

	char_index^ += 1
	func_def.name, err = expect_custom_keyword(
		tokens[char_index^],
		"Expected function name in function definition",
	)
	if !err.ok do return

	char_index^ += 1
	err = expect_token(
		tokens[char_index^],
		Token(Bracket{.Round, .Opening}),
		"Expected ( in function",
	)
	if !err.ok do return

	for {
		char_index^ += 1
		if tokens[char_index^] == Token(Bracket{.Round, .Closing}) do break
		arg_name: CustomKeyword
		arg_name, err = expect_custom_keyword(
			tokens[char_index^],
			"Expected argument name in function definition",
		)
		if !err.ok do return

		append(&func_def.args, arg_name)

		char_index^ += 1
		if tokens[char_index^] == Token(Bracket{.Round, .Closing}) do break
		err = expect_token(
			tokens[char_index^],
			Comma,
			"Expected ) or comma after function argument",
		)
	}

	char_index^ += 1
	func_def.block, err = capture_block(tokens, char_index)
	if !err.ok do return

	return func_def, err
}

// Try to match a `VariableDefinition` statement under the cursor
@(private)
try_match_var_definition :: proc(
	tokens: t.TokenStream,
	char_index: ^int,
) -> (
	var_definition: Maybe(VariableDefinition),
	err := ParseError{ok = true},
) {
	using t
	if tokens[char_index^] != Token(Keyword(.Var)) do return
	var_definition = VariableDefinition{}
	var_def := &var_definition.?

	char_index^ += 1
	var_def.name, err = expect_custom_keyword(
		tokens[char_index^],
		"Expected variable name after `var` in variable definition",
	)
	if !err.ok do return

	char_index^ += 1
	err = expect_token(
		tokens[char_index^],
		Token(Operator(.Assign)),
		"Expected `=` after variable name in variable definition",
	)
	if !err.ok do return

	char_index^ += 1
	var_def.expr, err = capture_expression(tokens, char_index)
	if !err.ok do return

	return
}

// Try to match a `VariableAssignment` statement under the cursor
@(private)
try_match_var_assignment :: proc(
	tokens: t.TokenStream,
	char_index: ^int,
) -> (
	var_assignment: Maybe(VariableAssignment),
	err := ParseError{ok = true},
) {
	var_name, custom_keyword_err := expect_custom_keyword(tokens[char_index^], "")
	if !custom_keyword_err.ok do return

	// Ensure there is an `AssignmentOperator` after the custom keyword
	op, op_ok := tokens[char_index^ + 1].(t.Operator)
	if !op_ok do return
	ass_op, ass_op_ok := op.(t.AssignmentOperator)
	if !ass_op_ok do return

	char_index^ += 2 // skip name and operator
	expr: Expression
	expr, err = capture_expression(tokens, char_index)
	if !err.ok do return

	var_assignment = VariableAssignment {
		target_var = var_name,
		operator   = ass_op,
		expr       = expr,
	}

	return
}
