package main

import "core:fmt"
import "core:mem"
import "formatter"
import "parser"
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

	block, err := parser.parse(tokens)
	defer parser.destroy_block(block)
	if !err.ok {
		if found, ok := err.found.?; ok {
			fmt.eprintln("Syntax error: ", err.error_msg, ", found ", found, sep = "")
		} else {
			fmt.eprintln("Syntax error: ", err.error_msg, sep = "")
		}
	}

	fmt.println("=== Parsed: ===")
	formatter.display_block(block)
}
