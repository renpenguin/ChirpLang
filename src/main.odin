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
	if parser.display_syntax_error(parser_err) do os.exit(1)
	defer parser.destroy_block(block)

	std := libraries.build_std_scope()
	defer scope.destroy_scope(std)

	block_scope, scope_err := scope.build_scope(&block, std)
	if scope.display_scope_error(scope_err) do os.exit(1)
	defer scope.destroy_scope(block_scope)

	// TODO: if there is nothing aside from imports, functions and constants in the loaded block, set the main function as the primary block
	return_val, runtime_err := execute.execute_block(block, block_scope)
	if execute.display_runtime_error(runtime_err) do os.exit(1)
	if return_val.handle_by != .DontHandle {
		fmt.eprintln("Runtime error: return/break statement should not be used at file scope, found", return_val) // TODO: do this (and same for forever) in `scope.evaluate`
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
					fmt.eprintln("  ^", transmute(string)mem.Raw_String{cast(^u8)entry.memory, entry.size})
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
