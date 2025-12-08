package handlers

import (
	"blog/internal/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

type AuthRequest struct {
	Username string
	Password string
}

type AuthHandler struct {
	authService *services.AuthService
}

func NewAuthHandler(authService *services.AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

func (h *AuthHandler) Register(c *gin.Context) {

	var req AuthRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "请求参数错误：" + err.Error(),
		})
		return
	}

	user, err := h.authService.Register(req.Username, req.Password)
	if err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"msg":      "注册成功",
		"username": user.UserName,
		"user_id":  user.ID,
	})
}
