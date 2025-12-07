package main

import (
	"fmt"
	"log"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

type User struct {
	ID        int
	UserName  string `gorm:"size:255"`
	Age       uint
	Post      []Post
	PostCount uint
}

type Post struct {
	ID            int
	PostTitle     string `gorm:"size:255"`
	UserID        int
	User          User
	Comments      []Comment
	CommentCount  uint
	CommentStatus string `gorm:"size:20"`
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

	//创建文章

}

/*为 Post 模型添加一个钩子函数，在文章创建时自动更新用户的文章数量统计字段。*/
func (p *Post) AfterCreate(tx *gorm.DB) (err error) {
	result := tx.Debug().Model(&User{}).Where("id = ?", p.UserID).Update("post_count", gorm.Expr("post_count + ?", 1))
	if result.Error != nil {
		fmt.Println("评论增加失败！")
	}
	fmt.Println("评论增加成功！")
	return
}

/* 为 Comment 模型添加一个钩子函数，在评论删除时检查文章的评论数量，如果评论数量为 0，则更新文章的评论状态为 "无评论"。*/
func (c *Comment) AfterDelete(tx *gorm.DB) (err error) {
	result := tx.Debug().Model(&Post{}).Where("id = ?", c.PostID).Update("comment_count", gorm.Expr("comment_count - ?", 1))
	if result.Error != nil {
		fmt.Println("评论减少失败！")
	}

	var count int64
	tx.Model(&Comment{}).Where("post_id = ?", c.PostID).Count(&count)

	if count > 0 {
		fmt.Println("评论减少成功！")
	} else {
		tx.Model(&Post{}).Where("post_id = ?", c.PostID).Update("CommentStatus = ?", "无评论")
		fmt.Println("无评论！")
	}

	return
}
