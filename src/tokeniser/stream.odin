package tokeniser

TokenStream :: distinct [dynamic]Token

destroy_token_stream :: proc(tokens: TokenStream) {
	for token in tokens {
		#partial switch _ in token {
		case Keyword:
			keyword := token.(Keyword)
			#partial switch _ in keyword {
			case CustomKeyword:
				delete(string(keyword.(CustomKeyword)))
			}
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
