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
