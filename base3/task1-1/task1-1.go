package main

import (
	"fmt"
	"log"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

type Student struct {
	name  string
	age   int
	grade string
}

func main() {
	var db *gorm.DB
	// MySQL连接示例（替换为你的数据库信息）
	dsn := "root:123456@tcp(192.168.111.109:3306)/go_test?charset=utf8mb4&parseTime=True&loc=Local"
	var err error
	db, err = gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("failed to connect database")
	}
	println("Gorm连接数据库成功！")

	sqlDB, err := db.DB()
	if err != nil {
		fmt.Println("获取sqlDB失败")
	}

	// 编写SQL语句向 students 表中插入一条新记录，学生姓名为 "张三"，年龄为 20，年级为 "三年级"。
	_, err = sqlDB.Exec("insert into students(name,age,grade) values(?,?,?)", "张三", 20, "三年级")
	if err != nil {
		log.Println("插入失败", err)
	}
	log.Println("插入数据成功")

	// 编写SQL语句查询 students 表中所有年龄大于 18 岁的学生信息。
	rows, err := sqlDB.Query("select * from students where age > ?", 18)
	if err != nil {
		log.Println("查询失败", err)
	}
	for rows.Next() {
		var s Student
		db.ScanRows(rows, &s)
		if err != nil {
			log.Println("取查询数据失败", err)
		}
		log.Printf("student:%+v", s)
	}

	// 编写SQL语句将 students 表中姓名为 "张三" 的学生年级更新为 "四年级"。
	_, err = sqlDB.Exec("update students set grade = ? where name =?", "四年级", "张三")
	if err != nil {
		log.Println("更新失败", err)
	}
	log.Println("更新数据成功")

	// 编写SQL语句删除 students 表中年龄小于 15 岁的学生记录。
	_, err = sqlDB.Exec("delete from students where age <?", 15)
	if err != nil {
		log.Println("删除失败", err)
	}
	log.Println("删除数据成功")
}
