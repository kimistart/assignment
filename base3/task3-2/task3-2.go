/* 题目2：关联查询 */

package main

import (
	"fmt"
	"log"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

type Post struct {
	ID        int
	PostTitle string `gorm:"size:255"`
	UserID    int
	User      User
	Comments  []Comment
}

type User struct {
	ID       int
	UserName string `gorm:"size:255"`
	Age      int
	Posts    []Post
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

	// 编写Go代码，使用Gorm查询某个用户发布的所有文章及其对应的评论信息。
	user := User{UserName: "张三"}
	queryPostsAndCommons(db, user)

	// 编写Go代码，使用Gorm查询评论数量最多的文章信息。
	queryMaxCommons(db)
}

// 编写Go代码，使用Gorm查询某个用户发布的所有文章及其对应的评论信息。
func queryPostsAndCommons(db *gorm.DB, user User) {
	db.First(&user)
	if user.ID == 0 {
		fmt.Println("数据库中没有该用户")
		return
	}
	fmt.Println("查询到用户：", user)

	var userDetail User
	err := db.Preload("Posts.Comments").Where("id = ?", user.ID).First(&userDetail).Error
	if err != nil {
		fmt.Println("查询失败", err)
		return
	}

	fmt.Printf("发布的文章数：%d\n", len(userDetail.Posts))
	for i, post := range userDetail.Posts {
		fmt.Printf("文章%d《%v》", i+1, post.PostTitle)
		fmt.Printf("评论%d条\n", len(post.Comments))
		for j, comms := range post.Comments {
			fmt.Printf("评论%d:%s   ", j+1, comms.Comment)
		}
		fmt.Printf("\n")
	}
}

// 编写Go代码，使用Gorm查询评论数量最多的文章信息。
func queryMaxCommons(db *gorm.DB) {
	var post Post
	db.Debug().Model(&post).Joins("JOIN comments ON comments.post_id = posts.id").
		Group("posts.id").Order("count(comments.id) DESC").First(&post)

	fmt.Println("评论数量最多的文章是：", post.PostTitle)
}
