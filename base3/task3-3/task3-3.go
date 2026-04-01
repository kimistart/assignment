package main

import (
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

	//创建用户
	user := User{UserName: "张三", Age: 25}
	db.Create(&user)

	//创建文章
	post := Post{PostTitle: "go学习", UserID: user.ID, CommentStatus: "有评论"}
	result := db.Create(&post)
	if result.Error != nil {
		log.Fatal("创建文章失败:", result.Error)
	}
	log.Printf("创建文章: %s (ID: %d) 成功\n", post.PostTitle, post.ID)

	//创建评论
	comment := Comment{Comment: "okokok", PostID: post.ID}
	db.Create(&comment)
	log.Printf("创建评论: %s 成功\n", comment.Comment)

	//删除评论
	db.Delete(&comment)
	log.Printf("删除评论: %s 成功\n", comment.Comment)
}

/*为 Post 模型添加一个钩子函数，在文章创建时自动更新用户的文章数量统计字段。*/
func (p *Post) AfterCreate(tx *gorm.DB) (err error) {
	result := tx.Debug().Model(&User{}).Where("id = ?", p.UserID).Update("post_count", gorm.Expr("post_count + ?", 1))
	if result.Error != nil {
		log.Println("文章数量增加失败！")
	}
	log.Println("文章数量增加成功！")
	return
}

/* 为 Comment 模型添加一个钩子函数，在评论删除时检查文章的评论数量，如果评论数量为 0，则更新文章的评论状态为 "无评论"。*/
func (c *Comment) AfterDelete(tx *gorm.DB) (err error) {

	var count int64
	tx.Model(&Comment{}).Where("post_id = ?", c.PostID).Count(&count)

	result := tx.Debug().Model(&Post{}).Where("id = ?", c.PostID).Update("comment_count", count)
	if result.Error != nil {
		log.Println("评论减少失败！", result.Error)
	}

	log.Println("评论数量更新成功！")

	if count == 0 {
		tx.Model(&Post{}).Where("id = ?", c.PostID).Update("comment_status", "无评论")
		log.Println("评论状态更新成功！")
	}

	return
}
