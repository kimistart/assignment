package models

import (
	"gorm.io/gorm"
)

type User struct {
	gorm.Model
	Username  string `gorm:"size:255;unique;not null"`
	Password  string `gorm:"size:100;not null"`
	Email     string `gorm:"size:100;unique;not null"`
	Post      []Post
	PostCount uint
}

type Post struct {
	gorm.Model
	Title         string `gorm:"size:255;not null"`
	Content       string `gorm:"not null"`
	UserID        uint
	User          User
	Comments      []Comment
	CommentCount  uint
	CommentStatus string `gorm:"size:20"`
}

type Comment struct {
	gorm.Model
	Content string `gorm:"not null"`
	UserID  uint
	User    User
	PostID  uint
	Post    Post
}
