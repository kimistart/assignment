/* 题目1：模型定义
假设你要开发一个博客系统，有以下几个实体： User （用户）、 Post （文章）、 Comment （评论）。
要求 ：
使用Gorm定义 User 、 Post 和 Comment 模型，其中 User 与 Post 是一对多关系（一个用户可以发布多篇文章）， Post 与 Comment 也是一对多关系（一篇文章可以有多个评论）。
编写Go代码，使用Gorm创建这些模型对应的数据库表。 */

package main

import (
	"log"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

type User struct {
	ID       int
	UserName string `gorm:"size:255"`
	Age      int
	Post     []Post
}

type Post struct {
	ID        int
	PostTitle string `gorm:"size:255"`
	UserID    int
	User      User
	Comments  []Comment
}

type Comment struct {
	ID      int
	Comment string
	PostID  int
	Post    Post
}

func main() {
	var db *gorm.DB
	dsn := "root:123456@tcp(192.168.111.109:3306)/blog?charset=utf8mb4&parseTime=True&loc=Local"
	var err error
	db, err = gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("failed to connect database")
	}
	println("Gorm连接数据库成功！")

	db.AutoMigrate(&User{})
	db.AutoMigrate(&Post{})
	db.AutoMigrate(&Comment{})
}
