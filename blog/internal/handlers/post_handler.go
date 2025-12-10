package handlers

import (
	"blog/internal/models"
	"blog/internal/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

type PostHandler struct {
	postService *services.PostService
}

func NewPostHandler(postService *services.PostService) *PostHandler {
	return &PostHandler{postService: postService}
}

func (h *PostHandler) CreatePost(c *gin.Context) {

	var post models.Post

	if err := c.ShouldBindJSON(&post); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "请求参数错误xxx：" + err.Error(),
		})
		return
	}

	cPost, err := h.postService.CreatePost(post)
	if err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"msg":   "文章创建成功",
		"title": cPost.Title,
	})
}
