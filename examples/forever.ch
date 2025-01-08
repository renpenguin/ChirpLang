import random, time

func main() {
	print("hi!")

	var total = 0
	forever {
		let dice_roll = random:range(1,6)
		print(f"Rolled a {dice_roll}!")

		total += dice_roll
		print("Total:", total)

		time:sleep(0.1)
	}
}

main()
