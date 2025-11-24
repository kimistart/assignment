package main

import "fmt"

// 给你一个有序数组 nums ，请你原地删除重复出现的元素，使每个元素只出现一次，返回删除后数组的新长度。
// 不要使用额外的数组空间，你必须在原地修改输入数组并在使用 O(1) 额外空间的条件下完成。
// 一个慢指针 i 用于记录不重复元素的位置，一个快指针 j 用于遍历数组，
// 当 nums[i] 与 nums[j] 不相等时，将 nums[j] 赋值给 nums[i + 1]，并将 i 后移一位。

func count(nums []int) (int, []int) {

	i := 0
	//1 2 2 1
	for j := 1; j < len(nums); j++ {
		if nums[j] != nums[i] {
			fmt.Println("位移前： ", nums)
			fmt.Println("nums[i]", nums[i], "nums[j]", nums[j])
			nums[i+1] = nums[j]
			fmt.Println("位移后： ", nums)
			i++
		}
	}

	return i + 1, nums[:i+1]
}

/* func main() {
	nums := [10]int{0, 0, 1, 1, 1, 2, 2, 3, 3, 4}
	len, arr := count(nums[:])
	fmt.Println("新长度", len, "新数组", arr)
} */
