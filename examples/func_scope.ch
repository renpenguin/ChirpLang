var a = 1

func bar() {
	let x = 2
	a = x
	foo()
}

func foo() {
	let x = x + 1
	print(x, a)
}

let x = 3

foo() // Out: `4 1`
bar() // Out: `4 2`
