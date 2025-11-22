package main

import "fmt"

func only_one(arr []int) {

	m := make(map[int]int)

	for _, v := range arr {
		m[v]++
	}

	for k, v := range m {
		if v == 1 {
			fmt.Print(k, "只出现了一次")
		}
	}
}

/* func main() {
	arr := []int{1, 1, 2, 2, 3, 3, 4, 4, 5}

	only_one(arr)
}
*/
