package services

import (
	"blog/internal/models"
	"blog/internal/repository/db_mysql"
	"errors"
	"time"

	"github.com/dgrijalva/jwt-go"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

var ErrInvalidCredentials = errors.New("invalid username or password")
var ErrInternalServer = errors.New("failed to generate token")

const (
	securityKey = "qkhPAGA13HocW3GAEWwb"
	// defaultPassword = "123456"
)

type AuthService struct {
	db *gorm.DB
}

func NewAuthService(db *gorm.DB) *AuthService {
	return &AuthService{db: db}
}

func (s *AuthService) Register(u models.User) (*models.User, error) {

	// 加密密码
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(u.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, errors.New("failed to hash password")
	}

	user := &models.User{
		Username: u.Username,
		Password: string(hashedPassword),
		Email:    u.Email,
	}

	if err := db_mysql.DB.Create(&user).Error; err != nil {
		return nil, errors.New("failed to create user")
	}

	return user, nil
}

func (s *AuthService) Login(username string, password string) (string, error) {

	var storedUser models.User
	if err := db_mysql.DB.Where("username = ?", username).First(&storedUser).Error; err != nil {
		return "", ErrInvalidCredentials
	}

	// 验证密码
	if err := bcrypt.CompareHashAndPassword([]byte(storedUser.Password), []byte(password)); err != nil {
		return "", ErrInvalidCredentials
	}

	// 生成 JWT
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"id":       storedUser.ID,
		"username": storedUser.Username,
		"exp":      time.Now().Add(time.Hour * 24).Unix(),
	})

	stringToken, err := token.SignedString([]byte(securityKey))
	if err != nil {
		return "", ErrInternalServer
	}
	// 剩下的逻辑...
	return stringToken, nil
}
