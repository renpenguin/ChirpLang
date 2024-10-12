package main

import "core:fmt"
import "tokeniser"

main :: proc() {
	tokens := tokeniser.tokenise(#load("../examples/hello_world.lc", string))
	defer delete(tokens)

	fmt.println("------------- Loaded tokens:")
	fmt.println(tokens)
	fmt.println("------------- Parsed text as:")
	fmt.println(tokens_to_string(tokens[:]))
}
