/* 题目 ：编写一个程序，使用通道实现两个协程之间的通信。一个协程生成从1到10的整数，并将这些整数发送到通道中，另一个协程从通道中接收这些整数并打印出来。
考察点 ：通道的基本使用、协程间通信。
*/

package main

import (
	"fmt"
)

func sendData(ch chan<- int) {
	for i := 1; i < 11; i++ {
		ch <- i
		fmt.Println("send:", i)
	}
	close(ch)
}

func receiveData(ch <-chan int) {
	for v := range ch {
		fmt.Println("receive:", v)
	}
}

/* func main() {
	ch := make(chan int, 3)
	go sendData(ch)
	go receiveData(ch)

	timeout := time.After(2 * time.Second)

	for {
		select {
		case v, ok := <-ch:
			if !ok {
				fmt.Println("channel 已关闭")
				return
			}
			fmt.Printf("主goroutine接收到：", v)
		case <-timeout:
			fmt.Println("超时了")
			return
		default:
			fmt.Println("等待数据中....")
			time.Sleep(500 * time.Millisecond)
		}
	}
} */
