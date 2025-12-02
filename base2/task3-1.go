package main

import (
	"math"
)

/* 题目 ：定义一个 Shape 接口，包含 Area() 和 Perimeter() 两个方法。然后创建 Rectangle 和 Circle 结构体，实现 Shape 接口。
在主函数中，创建这两个结构体的实例，并调用它们的 Area() 和 Perimeter() 方法。
考察点 ：接口的定义与实现、面向对象编程风格。*/

type Shape interface {
	Area() float64
	Perimeter() float64
}

type Rectangle struct {
	Width  float64
	Height float64
}

func (r Rectangle) Area() float64 {
	return r.Width * r.Height
}

func (r Rectangle) Perimeter() float64 {
	return 2 * (r.Width + r.Height)
}

type Circle struct {
	Radius float64
}

func (c Circle) Area() float64 {
	return math.Pi * c.Radius * c.Radius
}

func (c Circle) Perimeter() float64 {
	return 2 * (math.Pi * c.Radius)
}

/* func main() {
	r := Rectangle{Width: 8, Height: 4}
	fmt.Println("矩形面积：", r.Area())
	fmt.Println("矩形周长：", r.Perimeter())

	c := Circle{Radius: 4}
	fmt.Println("圆形面积：", c.Area())
	fmt.Println("圆形周长：", c.Perimeter())
} */
