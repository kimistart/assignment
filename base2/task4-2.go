/*
	题目 ：实现一个带有缓冲的通道，生产者协程向通道中发送100个整数，消费者协程从通道中接收这些整数并打印。

考察点 ：通道的缓冲机制。
*/
package main

import (
	"fmt"
	"sync"
)

func producer(ch chan<- int, wg *sync.WaitGroup) {

	defer wg.Done()

	for i := 0; i < 100; i++ {
		ch <- i
		fmt.Println("生产者发送：", i)
	}

	close(ch)
}

func consumer(ch <-chan int, wg *sync.WaitGroup) {

	defer wg.Done()

	var count int

	for v := range ch {
		fmt.Println("消费者接收：", v)
		count++
	}
	fmt.Printf("共接收：%d 个整数 \n", count)
}

/*
func main() {
	bufferSize := 10

	ch := make(chan int, bufferSize)

	var wg sync.WaitGroup
	wg.Add(2)

	go producer(ch, &wg)
	go consumer(ch, &wg)

	wg.Wait()
	fmt.Println("程序结束")
} */
