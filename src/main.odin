package main

import "core:fmt"
import "tokeniser"
import "formatter"

main :: proc() {
	tokens := tokeniser.tokenise(#load("../examples/hello_world.lc", string))
	defer delete(tokens)

	fmt.println("------------- Loaded tokens:")
	fmt.println(tokens)
	fmt.println("------------- Parsed text as:")
	parsed_string := formatter.format(tokens[:])
	defer delete(parsed_string)
	fmt.println(parsed_string)
}
