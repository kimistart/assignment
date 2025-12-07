/* 题目2：实现类型安全映射
假设有一个 books 表，包含字段 id 、 title 、 author 、 price 。
要求 ：
定义一个 Book 结构体，包含与 books 表对应的字段。
编写Go代码，使用Sqlx执行一个复杂的查询，例如查询价格大于 50 元的书籍，并将结果映射到 Book 结构体切片中，确保类型安全。 */

package main

import (
	"fmt"
	"log"

	_ "github.com/go-sql-driver/mysql"
	"github.com/jmoiron/sqlx"
)

type Book struct {
	ID     int
	Title  string
	Author string
	Price  float64
}

func main() {
	var db *sqlx.DB
	dsn := "root:123456@tcp(192.168.111.109:3306)/go_test?charset=utf8mb4&parseTime=True&loc=Local"
	var err error
	db, err = sqlx.Open("mysql", dsn)

	if err != nil {
		log.Fatal("failed to connect database")
	}
	println("sqlx连接数据库成功！")

	defer db.Close()

	books := []Book{}

	sqlStr := "select id,title,author,price from books where price > ?"
	if err = db.Select(&books, sqlStr, 50); err != nil {
		fmt.Println("查询失败")
	}

	fmt.Printf("books:%#v", books)
}
