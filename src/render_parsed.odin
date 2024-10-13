package main

import "core:fmt"
import "parser"

render_block :: proc(block: parser.Block, indent := 0) {
	for instruction in block {
		for i := 0; i < indent; i += 1 {
			fmt.print("  ")
		}

		#partial switch _ in instruction {
		case parser.Import:
			fmt.println("[Import]",instruction)
		case parser.FunctionDefinition:
			func_def := instruction.(parser.FunctionDefinition)
			fmt.println("[FuncDef] ", func_def.name, func_def.args, ": ", sep="")
			render_block(func_def.block, indent + 1)
		case parser.Forever:
			fmt.println("[Forever]:")
			render_block(instruction.(parser.Forever).block, indent + 1)
		case parser.VariableDefinition:
			var_def := instruction.(parser.VariableDefinition)
			fmt.println("[Var]", var_def.name, "[is set to]", var_def.expr)
		case parser.Expression:
			expr := instruction.(parser.Expression)
			fmt.println("[Expr]", expr)
		}
	}
}
