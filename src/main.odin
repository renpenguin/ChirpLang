package main

import "core:fmt"

main :: proc() {
	tokens := tokenise(#load("../examples/hello_world.lc", string))
	defer delete(tokens)

	fmt.println("------------- Loaded tokens:")
	fmt.println(tokens)
	fmt.println("------------- Parsed text as:")
	fmt.println(tokens_to_string(tokens[:]))
}
