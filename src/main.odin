package main

import "core:fmt"
import "core:mem"
import "core:os"
import "execute"
import "formatter"
import "parser"
import "scope"
import "scope/libraries"
import "tokeniser"

main :: proc() {
	when ODIN_DEBUG { 	// Memory Allocation Tracker
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	tokens := tokeniser.tokenise(#load("../examples/function.lc", string))

	block, parser_err := parser.parse(tokens)
	defer parser.destroy_block(block)
	if !parser_err.ok {
		if found, ok := parser_err.found.?; ok {
			fmt.eprintln("Syntax error: ", parser_err.msg, ", found ", found, sep = "")
		} else {
			fmt.eprintln("Syntax error: ", parser_err.msg, sep = "")
		}
		os.exit(1)
	}

	std := libraries.build_std_scope()
	defer scope.destroy_scope(std)

	block_scope, scope_err := scope.build_scope(&block, &std)
	defer scope.destroy_scope(block_scope)

	if !scope_err.ok {
		switch _ in scope_err.err_source {
		case []parser.NameDefinition:
			fmt.eprintln("Scope error: invalid path:", scope_err)
		case parser.NameDefinition:
			fmt.eprintln("Scope error: couldn't find name at path:", scope_err)
		case scope.Module:
			fmt.eprintln("Scope error: imported module already exists:", scope_err)
		}
		os.exit(1)
	}

	// TODO: if there is nothing aside from imports, functions and constants in the loaded block, set the main function as the primary block

	return_val, err := execute.execute_block(block, block_scope)
	if !execute.is_runtime_error_ok(err) {
		fmt.eprint("Runtime error: ")
		switch _ in err {
		case execute.TypeError:
			fmt.eprintln("Type error", err.(execute.TypeError))
		case scope.BuiltInFunctionError:
			fmt.eprintln("C function error", err.(scope.BuiltInFunctionError))
		case execute.NoError:
			panic("Unreachable")
		}
		os.exit(1)
	}
	if _, ok := return_val.(parser.NoneType); !ok {
		fmt.eprintln(
			"Runtime error: return statement should only be used in a function, found",
			return_val,
		) // TODO: do this (and same for forever) in `scope.evaluate`
		os.exit(1)
	}
}
