package formatter

import p "../parser"
import "core:fmt"
import "core:strings"

// Prints a `p.Block` to `stdout` in a pseudo language
display_block :: proc(block: p.Block, indent := 0, ignore_scope_statements := false) {
	using p

	for instruction in block {
		for i := 0; i < indent; i += 1 {
			fmt.print("  ")
		}

		#partial switch _ in instruction {
		case ImportStatement:
			if ignore_scope_statements do continue
			fmt.print("[Import]")
			for lib in instruction.(ImportStatement) {
				fmt.printf(" [%v]", name_ref_to_string(lib))
			}
			fmt.println()
		case FunctionDefinition:
			if ignore_scope_statements do continue
			func_def := instruction.(FunctionDefinition)
			fmt.println("[FuncDef] ", func_def.name, func_def.args, ": ", sep = "")
			display_block(func_def.block, indent + 1)
		case While:
			fmt.println("[While]:")
			display_expression(instruction.(p.While).condition)
			display_block(instruction.(While).block, indent + 1)
		case VariableDefinition:
			var_def := instruction.(VariableDefinition)
			fmt.print("[VarDef]", var_def.name, "[=] ")
			display_expression(var_def.expr)
			fmt.println()
		case VariableAssignment:
			var_ass := instruction.(VariableAssignment)
			fmt.print("[VarAss]", name_ref_to_string(var_ass.target), "[", var_ass.operator, "] ")
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

// Prints a `p.Expresion` to `stdout` in a human-readable pseudo language
@(private)
display_expression :: proc(expr: p.Expression) {
	using p

	#partial switch _ in expr {
	case Operation:
		op := expr.(Operation)
		fmt.print("Operation{ ")
		display_expression(op.left^)
		fmt.print(" [", op.op, "] ", sep = "")
		display_expression(op.right^)
		fmt.print(" }")

	case FunctionCall:
		func_call := expr.(FunctionCall)
		fmt.print("FunctionCall{", name_ref_to_string(func_call.name))

		if len(func_call.args) > 0 {
			fmt.print(", ")
			for arg in func_call.args[:len(func_call.args) - 1] {
				display_expression(arg)
				fmt.print(", ")
			}
			display_expression(func_call.args[len(func_call.args) - 1])
		}
		fmt.print(" }")

	case FormatString:
		fmt.print("Format{ \"", expr.(FormatString), "\" }", sep = "")

	case NameReference:
		fmt.print(name_ref_to_string(expr.(p.NameReference)))

	case:
		fmt.print(expr)
	}
}

@(deferred_out = delete_string)
name_ref_to_string :: proc(name_ref: p.NameReference) -> string {
	sb := strings.builder_make()
	// defer strings.builder_destroy(&sb)
	if path, ok := name_ref.path.?; ok {
		for namespace in path {
			strings.write_string(&sb, string(namespace))
			strings.write_rune(&sb, ':')
		}
	}
	strings.write_string(&sb, string(name_ref.name))

	return strings.to_string(sb)
}

@(private)
delete_string :: proc(str: string) {delete(str)}
