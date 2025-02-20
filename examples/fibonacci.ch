func fib(n int) -> int {
    if n < 2 {
        return 1
    }
    return fib(n - 1) + fib(n - 2)
}

let n = 6
print(f"{n}th number of the fibonacci sequence: {fib(n)}")
