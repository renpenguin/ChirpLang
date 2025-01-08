var a = 1

func bar() {
	var x = 2
	a = x
	foo()
}

func foo() {
	var x = x + 1
	print(x, a)
}

var x = 3

foo() // Out: `4 1`
bar() // Out: `4 2`
