package main

// 给定一个整数数组 nums 和一个目标值 target，请你在该数组中找出和为目标值的那两个整数

func findInt(arr []int, target int) map[int]int {
	m := make(map[int]bool)
	result := make(map[int]int)
	for _, v := range arr {
		last := target - v
		if used, exist := m[last]; exist {
			if !used {
				result[v] = last
				m[last] = true
				continue
			}

		}
		m[v] = false
	}
	return result
}

/* func main() {
	arr := []int{1, 2, 3, 4, 5, 6}
	target := 6
	result := findInt(arr[:], target)
	fmt.Println("两个整数是", result)
} */
