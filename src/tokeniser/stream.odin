package tokeniser

TokenStream :: distinct [dynamic]Token

destroy_token_stream :: proc(tokens: TokenStream) {
	for token in tokens {
		#partial switch _ in token {
			case Keyword:
				delete(string(token.(Keyword)))
			case Literal:
				literal := token.(Literal)
				#partial switch _ in literal {
					case string:
						delete(literal.(string))
				}
		}
	}

	delete(tokens)
}