// example of a function definition
func add(first int, second int) -> int {
	print("adding", first, "and", second)
	return first + second
}

print(
	3, "plus", 2, "is",
	add(3, 2)
)
// add(1, "2") // this throws an error
