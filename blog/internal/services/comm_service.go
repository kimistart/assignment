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

	/* 	id, err := strconv.ParseUint(postId, 10, 0)
	   	if err != nil {
	   		return nil, errors.New("cov error")
	   	}

	   	c.PostID = uint(id) */

	if err := db_mysql.DB.Create(&c).Error; err != nil {
		return errors.New("create comment failed")
	}

	return nil
}
