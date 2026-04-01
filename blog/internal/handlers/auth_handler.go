package handlers

import (
	"blog/internal/models"
	"blog/internal/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

type AuthHandler struct {
	authService *services.AuthService
}

func NewAuthHandler(authService *services.AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

func (h *AuthHandler) Register(c *gin.Context) {

	var user models.User

	if err := c.ShouldBindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "请求参数错误xxx：" + err.Error(),
		})
		return
	}

	cUser, err := h.authService.Register(user)
	if err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"msg":       "注册成功",
		"username":  cUser.Username,
		"userEmail": cUser.Email,
	})
}

func (h *AuthHandler) Login(c *gin.Context) {

	var user models.User

	if err := c.ShouldBindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "请求参数错误xxx：" + err.Error(),
		})
		return
	}

	token, err := h.authService.Login(user.Username, user.Password)
	if err != nil {
		errorMsg := err.Error()
		statusCode := http.StatusInternalServerError

		if err == services.ErrInvalidCredentials {
			statusCode = http.StatusUnauthorized
			errorMsg = "invalid username or password"
		}
		if err == services.ErrInvalidCredentials {
			statusCode = http.StatusInternalServerError
			errorMsg = "internal server error"
		}

		c.JSON(statusCode, gin.H{"error": errorMsg})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"msg":   "登录成功",
		"token": token,
	})
}
