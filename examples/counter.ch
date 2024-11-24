import time

var counter = 0

print("Counting from", counter)

forever {
	counter += 1
	print("We have now counted", counter, "times")
	time:sleep(0.2)
}
