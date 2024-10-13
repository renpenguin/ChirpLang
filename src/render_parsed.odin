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
			fmt.println("[Import]", instruction)
		case FunctionDefinition:
			func_def := instruction.(FunctionDefinition)
			fmt.println("[FuncDef] ", func_def.name, func_def.args, ": ", sep = "")
			render_block(func_def.block, indent + 1)
		case Forever:
			fmt.println("[Forever]:")
			render_block(instruction.(Forever).block, indent + 1)
		case VariableDefinition:
			var_def := instruction.(VariableDefinition)
			fmt.print("[VarSet]", var_def.name, "[is set to] ")
			render_expression(var_def.expr)
			fmt.println()
		case VariableAssignment:
			var_ass := instruction.(VariableAssignment)
			fmt.print("[VarAss]", var_ass.target_var, "[", var_ass.operator, "] ")
			render_expression(var_ass.expr)
			fmt.println()
		case Expression:
			expr := instruction.(Expression)
			fmt.print("[Expr] ")
			render_expression(expr)
			fmt.println()
		}
	}
}

render_expression :: proc(expr: parser.Expression) {
	#partial switch _ in expr {
		case parser.Operation:
			op := expr.(parser.Operation)
			fmt.print("Operation{left = ")
			render_expression(op.left^)
			fmt.print(", op = ",op.op, ", right = ", sep = "")
			render_expression(op.right^)
			fmt.print("}")

		case parser.FunctionCall:
			func_call := expr.(parser.FunctionCall)
			fmt.print("FunctionCall{ ", func_call.name, ", ", sep = "")

			for arg in func_call.args[:len(func_call.args)-1] {
				render_expression(arg)
				fmt.print(", ")
			}
			render_expression(func_call.args[len(func_call.args)-1])
			fmt.print(" }")

		case parser.FormatString:
			fmt.print("Format{ \"", expr.(parser.FormatString), "\" }", sep="")

		case:
			fmt.print(expr)
	}
}
