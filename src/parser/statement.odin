package parser

import t "../tokeniser"

// Brings libraries or functions into scope. Expected pattern `import $library$, ...;`
ImportStatement :: distinct [dynamic]NameReference

// Defines a new variable in the current scope. Expected pattern `var $name$ = $expr$;`
VariableDefinition :: struct {
	name: NameDefinition,
	expr: Expression,
}

// Operation that either is or ends with `=`. Expected pattern `$name$ $operator$ $expr$;`
VariableAssignment :: struct {
	target:   NameReference,
	operator: t.AssignmentOperator,
	expr:     Expression,
}

FunctionArgument :: struct {
	name: NameDefinition,
	type: ValueType,
}
// Defines a function. Expected pattern `func $name$($name$, ...) $block$`
FunctionDefinition :: struct {
	name:        NameDefinition,
	args:        [dynamic]FunctionArgument,
	return_type: ValueType,
	block:       Block,
}

// Executes a block until `Break` is triggered. Expected patten `forever $block$`
Forever :: struct {
	block: Block,
}

Return :: distinct Expression

Statement :: union {
	ImportStatement,
	VariableDefinition,
	VariableAssignment,
	FunctionDefinition,
	Forever,
	Expression,
	Return,
}

// Captures a block of statements surrounded by {}. `token_index` should be the index of the first {
@(private)
capture_block :: proc(
	tokens: t.TokenStream,
	token_index: ^int,
) -> (
	block: Block,
	err: SyntaxError,
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

// Try to match an `ImportStatement` under the cursor
@(private)
try_match_import :: proc(
	tokens: t.TokenStream,
	char_index: ^int,
) -> (
	import_statement: Maybe(ImportStatement),
	err := SyntaxError{ok = true},
) {
	using t
	if tokens[char_index^] != Token(Keyword(.Import)) do return
	import_statement = ImportStatement{}

	for {
		char_index^ += 1
		keyword: CustomKeyword
		keyword, err = expect_custom_keyword(
			tokens[char_index^],
			"Expected library reference in import statement",
		)
		if !err.ok do return

		append(&import_statement.?, keyword_to_name_ref(keyword))

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
	err := SyntaxError{ok = true},
) {
	using t
	if tokens[char_index^] != Token(Keyword(.Func)) do return
	func_def: FunctionDefinition

	char_index^ += 1
	func_def.name, err = expect_name_def(
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
		arg_name: NameDefinition
		arg_name, err = expect_name_def(
			tokens[char_index^],
			"Expected argument name in function definition",
		)
		if !err.ok do return

		char_index^ += 1
		kw, kw_ok := tokens[char_index^].(Keyword)
		if !kw_ok do return nil, SyntaxError{msg = "Expected argument type after argument name in function definition"}
		tkw, tkw_ok := kw.(t.TypeKeyword)
		if !tkw_ok do return nil, SyntaxError{msg = "Expected argument type after argument name in function definition"}

		append(&func_def.args, FunctionArgument{arg_name, ValueType(tkw)})

		char_index^ += 1
		if tokens[char_index^] == Token(Bracket{.Round, .Closing}) do break
		err = expect_token(
			tokens[char_index^],
			Comma,
			"Expected ) or comma after function argument",
		)
	}

	if expect_token(tokens[char_index^ + 1], t.Token(t.Keyword(.ReturnType)), "").ok {
		char_index^ += 2

		EXPECTED_TYPE_KEYWORD_ERROR :: "Expected type keyword after -> in function definition"
		kw, kw_ok := tokens[char_index^].(t.Keyword)
		if !kw_ok do return nil, SyntaxError{msg = EXPECTED_TYPE_KEYWORD_ERROR, found = tokens[char_index^]}
		tkw, tkw_ok := kw.(t.TypeKeyword)
		if !tkw_ok do return nil, SyntaxError{msg = EXPECTED_TYPE_KEYWORD_ERROR, found = kw}

		func_def.return_type = tkw
	} else {
		func_def.return_type = .None
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
	err := SyntaxError{ok = true},
) {
	using t
	if tokens[char_index^] != Token(Keyword(.Var)) do return
	var_definition = VariableDefinition{}
	var_def := &var_definition.?

	char_index^ += 1
	var_def.name, err = expect_name_def(
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
	err := SyntaxError{ok = true},
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
		target   = keyword_to_name_ref(var_name),
		operator = ass_op,
		expr     = expr,
	}

	return
}
