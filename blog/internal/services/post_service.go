package services

import (
	"blog/internal/models"
	"blog/internal/repository/db_mysql"
	"errors"

	"gorm.io/gorm"
)

type PostService struct {
	db *gorm.DB
}

func NewPostService(db *gorm.DB) *PostService {
	return &PostService{db: db}
}

func (s *PostService) CreatePost(p models.Post) (post *models.Post, err error) {

	if err := db_mysql.DB.Create(&p).Error; err != nil {
		return nil, errors.New("failed to create post")
	}

	return &p, nil
}

func (s *PostService) PostList() (post []models.Post, err error) {

	var posts []models.Post

	if err := db_mysql.DB.Find(&posts).Error; err != nil {
		return nil, errors.New("failed to get post list")
	}

	return posts, nil
}

func (s *PostService) UpdatePost(postId uint, title string, content string) (err error) {

	return db_mysql.DB.Model(&models.Post{}).
		Where("id=?", postId).
		Updates(map[string]interface{}{
			"title":   title,
			"content": content,
		}).Error
}
