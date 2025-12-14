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

	post.UserID = c.MustGet("user_id").(uint)

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

func (h *PostHandler) PostList(c *gin.Context) {

	posts, err := h.postService.PostList()
	if err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"msg":  "文章列表查询成功",
		"data": posts,
		"len":  len(posts),
	})
}

func (h *PostHandler) UpdatePost(c *gin.Context) {

	var post models.Post

	if err := c.ShouldBindJSON(&post); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"err": "请求参数错误" + err.Error(),
		})
	}

	err := h.postService.UpdatePost(post.ID, post.Title, post.Content)
	if err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"msg": "文章更新成功",
	})
}
