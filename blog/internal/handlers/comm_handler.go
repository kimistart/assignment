package handlers

import (
	"blog/internal/models"
	"blog/internal/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

type CommHandler struct {
	commService *services.CommService
}

func NewCommHandler(commService *services.CommService) *CommHandler {
	return &CommHandler{commService: commService}
}

func (h *CommHandler) CreateComment(c *gin.Context) {

	var comm models.Comment

	if err := c.ShouldBind(&comm); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.commService.CreatComment(comm); err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"msg":  "评论成功",
		"comm": comm.Content,
	})
}
