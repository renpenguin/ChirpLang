package main

import "core:fmt"
import "core:mem"
import "formatter"
import "parser"
import "scope"
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

	tokens := tokeniser.tokenise(#load("../examples/forever.lc", string))

	fmt.println("\n=== Tokenised: ===")
	fmt.println(tokens)

	fmt.println("\n=== Formatted: ===")
	fmt.println(formatter.format(tokens))

	block, parser_err := parser.parse(tokens)
	defer parser.destroy_block(block)
	if !parser_err.ok {
		if found, ok := parser_err.found.?; ok {
			fmt.eprintln("Syntax error: ", parser_err.error_msg, ", found ", found, sep = "")
		} else {
			fmt.eprintln("Syntax error: ", parser_err.error_msg, sep = "")
		}
	}

	fmt.println("=== Parsed: ===")
	formatter.display_block(block)

	fmt.println("=== Evaluating Scope ===")
	std := scope.build_std_scope()
	block_scope, scope_err := scope.build_scope(&block, &std)
	if !scope_err.ok do fmt.eprintln("Scope error:", scope_err.error_msg)
	scope_err = scope.evaluate_block_with_scope(block, block_scope)
	if !scope_err.ok do fmt.eprintln("Scope error:", scope_err.error_msg)
	formatter.display_block(block, ignore_scope_statements = true)
}
