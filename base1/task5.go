package main

import (
	"strconv"
)

func add(intArr [4]int) int {

	var str string

	for _, value := range intArr {
		// 将整数转换为字符串
		str += strconv.Itoa(value)
	}

	// 将字符串转换为整数
	num, _ := strconv.Atoi(str)

	return num + 1
}

/* func main() {
	intArr := [...]int{4, 5, 6, 7}
	fmt.Println(add(intArr))
} */
