package main

import (
	"fmt"
)

/* func main() {
	print()
	time.Sleep(3 * time.Second)
	fmt.Println("end")
} */

func print() {
	go func() {
		fmt.Println("奇数协程开始执行！") // 启动提示
		for i := 1; i < 11; i++ {
			if i%2 != 0 {
				// time.Sleep(1 * time.Second)
				fmt.Println("奇数:", i)
			}
		}
	}()

	go func() {
		fmt.Println("偶数协程开始执行！") // 启动提示
		for i := 1; i < 11; i++ {
			if i%2 == 0 {
				// time.Sleep(1 * time.Second)
				fmt.Println("偶数:", i)
			}
		}
	}()
}
