import time

var counter = 0
print(f"Counting from {counter}")

while counter < 10 {
    counter += 1
    print(f"We have now counted {counter} times")

    time:sleep(0.2)
}
