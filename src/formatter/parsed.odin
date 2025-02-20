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

		#partial switch inst in instruction {
		case ImportStatement:
			if ignore_scope_statements do continue
			fmt.print("[Import]")
			for lib in inst {
				fmt.printf(" [%v]", name_ref_to_string(lib))
			}
			fmt.println()
		case FunctionDefinition:
			if ignore_scope_statements do continue
			fmt.println("[FuncDef] ", inst.name, inst.args, ": ", sep = "")
			display_block(inst.block, indent + 1)
		case While:
			fmt.print("[While] ")
			display_expression(inst.condition)
			fmt.println(":")
			display_block(inst.block, indent + 1)
		case VariableDefinition:
			fmt.print("[VarDef]", inst.name, "[=] ")
			display_expression(inst.expr)
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
display_expression :: proc(expression: p.Expression) {
	using p

	switch expr in expression {
	case Operation:
		fmt.print("Operation{ ")
		display_expression(expr.left^)
		fmt.print(" [", expr.op, "] ", sep = "")
		display_expression(expr.right^)
		fmt.print(" }")

	case FunctionCall:
		fmt.print("FunctionCall{", name_ref_to_string(expr.name))

		if len(expr.args) > 0 {
			fmt.print(", ")
			for arg in expr.args[:len(expr.args) - 1] {
				display_expression(arg)
				fmt.print(", ")
			}
			display_expression(expr.args[len(expr.args) - 1])
		}
		fmt.print(" }")

	case FormatString:
		fmt.print("Format{ ")
		for arg in expr {
			display_expression(arg)
			fmt.print(", ")
		}
		fmt.print("\b\b }")

	case NameReference:
		fmt.print(name_ref_to_string(expr))

	case p.Value:
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
