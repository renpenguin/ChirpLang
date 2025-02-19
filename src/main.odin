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

run :: proc(input: string) {
	tokens := tokeniser.tokenise(input)

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

	block_scope, scope_err := scope.build_scope(&block, std)
	defer scope.destroy_scope(block_scope)

	if !scope_err.ok {
		switch scope_err.type {
		case .Redefinition:
			if _, ok := scope_err.err_source.(scope.Module); ok {
				fmt.eprintln(
					"Scope error: attempt to import module that already exists:",
					scope_err.err_source,
				)
			} else {
				fmt.eprintln("Scope error: redefinition of function", scope_err.err_source)
			}
		case .ModifiedImmutable:
			fmt.eprintln(
				"Scope error: attempted to modify immutable variable:",
				scope_err.err_source,
			)
		case .ModuleNotFound:
			fmt.eprintln("Scope error: couldn't find module:", scope_err.err_source)
		case .InvalidPath:
			fmt.eprintln("Scope error: invalid path:", scope_err.err_source)
		case .NotFoundAtPath:
			fmt.eprintln("Scope error: couldn't find name at path:", scope_err.err_source)
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
	if return_val.handle_by != .DontHandle {
		fmt.eprintln(
			"Runtime error: return/break statement should not be used at file scope, found",
			return_val,
		) // TODO: do this (and same for forever) in `scope.evaluate`
		os.exit(1)
	}
}

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

	if len(os.args) != 2 {
		fmt.eprintln("Argument error: Please use `chirp <file>`")
		os.exit(1)
	}

	if !os.exists(os.args[1]) {
		fmt.eprintln("Argument error: first argument is not a valid path. please pass a valid path")
		os.exit(1)
	}

	input, err := os.read_entire_file_from_filename_or_err(os.args[1])
	if err != nil {
		fmt.eprintln("File read error:", err)
	}
	defer delete(input)

	run(string(input))
}
