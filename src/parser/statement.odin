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

// Executes a block until `Break` is triggered
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
