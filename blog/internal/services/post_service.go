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
		return nil, errors.New("failed to create user")
	}

	return &p, nil
}
