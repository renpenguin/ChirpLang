package tokeniser

TokenStream :: distinct [dynamic]Token

// Fully destroy the TokenStream
destroy_token_stream :: proc(tokens: TokenStream) {
	for token in tokens {
		#partial switch tok in token {
		case Keyword:
			if custom_keyword, ok := tok.(CustomKeyword); ok {
				delete(string(custom_keyword))
			}
		case Literal:
			if str_literal, ok := tok.(string); ok {
				delete(string(str_literal))
			}
		}
	}

	delete(tokens)
}
