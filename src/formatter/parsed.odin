package formatter

import "../parser"
import "core:fmt"

// Prints a `parser.Block` to `stdout` in a pseudo language
display_block :: proc(block: parser.Block, indent := 0) {
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
			display_block(func_def.block, indent + 1)
		case Forever:
			fmt.println("[Forever]:")
			display_block(instruction.(Forever).block, indent + 1)
		case VariableDefinition:
			var_def := instruction.(VariableDefinition)
			fmt.print("[VarDef]", var_def.name, "[=] ")
			display_expression(var_def.expr)
			fmt.println()
		case VariableAssignment:
			var_ass := instruction.(VariableAssignment)
			fmt.print("[VarAss]", var_ass.target_var, "[", var_ass.operator, "] ")
			display_expression(var_ass.expr)
			fmt.println()
		case Expression:
			expr := instruction.(Expression)
			fmt.print("[Expr] ")
			display_expression(expr)
			fmt.println()
		}
	}
}

// Prints a `parser.Expresion` to `stdout` in a human-readable pseudo language
display_expression :: proc(expr: parser.Expression) {
	#partial switch _ in expr {
	case parser.Operation:
		op := expr.(parser.Operation)
		fmt.print("Operation{")
		display_expression(op.left^)
		fmt.print(" [", op.op, "] ", sep = "")
		display_expression(op.right^)
		fmt.print("}")

	case parser.FunctionCall:
		func_call := expr.(parser.FunctionCall)
		fmt.print("FunctionCall{ ", func_call.name, ", ", sep = "")

		for arg in func_call.args[:len(func_call.args) - 1] {
			display_expression(arg)
			fmt.print(", ")
		}
		display_expression(func_call.args[len(func_call.args) - 1])
		fmt.print(" }")

	case parser.FormatString:
		fmt.print("Format{ \"", expr.(parser.FormatString), "\" }", sep = "")

	case:
		fmt.print(expr)
	}
}
