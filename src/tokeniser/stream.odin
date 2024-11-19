package tokeniser

TokenStream :: distinct [dynamic]Token

// Fully destroy the TokenStream
destroy_token_stream :: proc(tokens: TokenStream) {
	for token in tokens {
		#partial switch _ in token {
		case Keyword:
			keyword := token.(Keyword)
			if custom_keyword, ok := keyword.(CustomKeyword); ok {
				delete(string(custom_keyword))
			}
		case Literal:
			literal := token.(Literal)
			if str_literal, ok := literal.(string); ok {
				delete(string(str_literal))
			}
		case Comment:
			delete(string(token.(Comment)))
		}
	}

	delete(tokens)
}
