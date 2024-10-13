package main

import "core:fmt"
import "parser"

render_block :: proc(block: parser.Block, indent := 0) {
	using parser

	for instruction in block {
		for i := 0; i < indent; i += 1 {
			fmt.print("  ")
		}

		#partial switch _ in instruction {
		case Import:
			fmt.println("[Import]",instruction)
		case FunctionDefinition:
			func_def := instruction.(FunctionDefinition)
			fmt.println("[FuncDef] ", func_def.name, func_def.args, ": ", sep="")
			render_block(func_def.block, indent + 1)
		case Forever:
			fmt.println("[Forever]:")
			render_block(instruction.(Forever).block, indent + 1)
		case VariableDefinition:
			var_def := instruction.(VariableDefinition)
			fmt.println("[VarSet]", var_def.name, "[is set to]", var_def.expr)
		case VariableAssignment:
			var_ass := instruction.(VariableAssignment)
			fmt.println("[VarAss]", var_ass.target_variable,"[",var_ass.operator,"]",var_ass.expr)
		case Expression:
			expr := instruction.(Expression)
			fmt.println("[Expr]", expr)
		}
	}
}
