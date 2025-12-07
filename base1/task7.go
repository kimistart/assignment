package main

import (
	"sort"
)

// 以数组 intervals 表示若干个区间的集合，其中单个区间为 intervals[i] = [starti, endi] 。
// 请你合并所有重叠的区间，并返回一个不重叠的区间数组，该数组需恰好覆盖输入中的所有区间。
// 可以先对区间数组按照区间的起始位置进行排序，然后使用一个切片来存储合并后的区间，
// 遍历排序后的区间数组，将当前区间与切片中最后一个区间进行比较，如果有重叠，则合并区间；
// 如果没有重叠，则将当前区间添加到切片中

func findArr(intervals [][2]int) [][2]int {

	slice := make([][2]int, len(intervals))
	copy(slice, intervals)

	sort.Slice(slice, func(i, j int) bool {
		return slice[i][0] < slice[j][0]
	})

	merged := [][2]int{slice[0]}

	for i := 0; i < len(slice); i++ {
		current := slice[i]
		last := merged[len(merged)-1]

		if current[0] < last[1] { //重叠
			if current[1] > last[1] {
				last[1] = current[1]
			}
		} else {
			merged = append(merged, current)
		}
	}

	return merged
}

/* func main() {
	intervals := [4][2]int{{1, 3}, {2, 6}, {8, 10}, {15, 18}}

	result := findArr(intervals[:])

	fmt.Println(result)
} */
