package main

import "core:fmt"
import "core:mem"
import "formatter"
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

	fmt.println("=== Loaded tokens: ===")
	fmt.println(tokens)
	fmt.println("=== Parsed text as: ===")
	parsed_string := formatter.format(tokens)
	defer delete(parsed_string)
	fmt.println(parsed_string)
}
