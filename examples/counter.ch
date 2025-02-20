import time

var counter = 0

print("Counting from", counter)

while counter < 10 {
    counter += 1
    print("We have now counted", counter, "times")

    time:sleep(0.2)
}
