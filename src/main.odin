package main

import "core:fmt"
import "core:mem"
import "formatter"
import "parser"
import "tokeniser"

main :: proc() {
	when ODIN_DEBUG {
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

	tokens := tokeniser.tokenise(#load("../examples/hello_world.lc", string))
	defer tokeniser.destroy_token_stream(tokens)

	fmt.println("=== Tokenised: ===")
	fmt.println(tokens)

	block, err := parser.parse(tokens)
	if !err.ok do fmt.println("Error while parsing: ", err.error_msg, ", found ", err.found, sep = "")

	fmt.println("\n== Code parsed into: ==")
	render_block(block)
}
