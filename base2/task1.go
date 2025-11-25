package main

import "fmt"

func add(p1 *int) int {
	*p1 += 10
	return *p1
}

func mult(arr *[]int) {
	for i := range *arr {
		(*arr)[i] *= 2
		fmt.Println((*arr)[i])
	}
}

/* func main() {
	//指针1
	a := 10
	fmt.Println(add(&a))

	//指针2
	arr := []int{2, 3, 4}
	mult(&arr)
} */
