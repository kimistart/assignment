/* 题目1：使用SQL扩展库进行查询
假设你已经使用Sqlx连接到一个数据库，并且有一个 employees 表，包含字段 id 、 name 、 department 、 salary 。
要求 ：
编写Go代码，使用Sqlx查询 employees 表中所有部门为 "技术部" 的员工信息，并将结果映射到一个自定义的 Employee 结构体切片中。
编写Go代码，使用Sqlx查询 employees 表中工资最高的员工信息，并将结果映射到一个 Employee 结构体中。 */

package main

import (
	"fmt"
	"log"

	_ "github.com/go-sql-driver/mysql"
	"github.com/jmoiron/sqlx"
	"github.com/shopspring/decimal"
)

type Employee struct {
	ID         int
	Name       string
	Department string
	Salary     decimal.Decimal
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

	employees := []Employee{}

	sqlStr := "select id,name,department,salary from employee where department=?"
	if err := db.Select(&employees, sqlStr, "技术部"); err != nil {
		fmt.Println("查询失败")
		return
	}

	fmt.Printf("users:%#v\n", employees)
}
