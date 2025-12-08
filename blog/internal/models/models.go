/* 题目1：模型定义
假设你要开发一个博客系统，有以下几个实体： User （用户）、 Post （文章）、 Comment （评论）。
要求 ：
使用Gorm定义 User 、 Post 和 Comment 模型，其中 User 与 Post 是一对多关系（一个用户可以发布多篇文章）， Post 与 Comment 也是一对多关系（一篇文章可以有多个评论）。
编写Go代码，使用Gorm创建这些模型对应的数据库表。 */

package models

import (
	"time"

	"blog/internal/repository/db_mysql"
)

type User struct {
	ID        int
	UserName  string `gorm:"size:255"`
	PassWord  string
	Email     string
	Post      []Post
	PostCount uint
}

type Post struct {
	ID            int
	Title         string `gorm:"size:255"`
	Content       string
	UserID        int
	User          User
	Comments      []Comment
	CommentCount  uint
	CommentStatus string `gorm:"size:20"`
	CreatedAt     time.Time
	UpdatedAt     time.Time
}

type Comment struct {
	ID        int
	Content   string
	UserID    int
	User      User
	PostID    int
	Post      Post
	CreatedAt time.Time
}

func main() {

	db_mysql.DB.AutoMigrate(&User{})
	db_mysql.DB.AutoMigrate(&Post{})
	db_mysql.DB.AutoMigrate(&Comment{})

}
