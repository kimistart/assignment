package main

func huiwen(x int) bool {

	if x < 0 {
		return false
	}

	digits := []int{}

	for x > 0 {
		digits = append(digits, x%10)
		x = x / 10
	}

	left, right := 0, len(digits)-1
	for left < right {
		if digits[left] != digits[right] {
			return false
		}
		left++
		right--
	}
	return true
}

/* func main() {
	arr := []int{1234, 123, 1221, 123321, 1234321, -121}
	for _, v := range arr {
		if huiwen(v) {
			fmt.Println(v, "是回文数")
		} else {
			fmt.Println(v, "不是回文数")
		}
	}

} */
