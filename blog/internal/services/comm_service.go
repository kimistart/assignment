package services

import (
	"blog/internal/models"
	"blog/internal/repository/db_mysql"
	"errors"

	"gorm.io/gorm"
)

type CommService struct {
	db *gorm.DB
}

func NewCommService(db *gorm.DB) *CommService {
	return &CommService{db: db}
}

func (s *CommService) CreatComment(c models.Comment) (err error) {

	if err := db_mysql.DB.Create(&c).Error; err != nil {
		return errors.New("create comment failed: " + err.Error())
	}

	return nil
}

func (s *CommService) CommsList(postId string) (p models.Post, err error) {

	result := db_mysql.DB.Preload("Comments").First(&p, postId)
	if result.Error != nil {
		return p, errors.New("create comment failed: " + result.Error.Error())
	}

	return p, nil
}
