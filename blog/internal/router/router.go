package router

import (
	"blog/internal/handlers"
	"blog/internal/services"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func SetupRouter(db *gorm.DB) *gin.Engine {

	router := gin.Default()

	authService := services.NewAuthService(db)
	authHandler := handlers.NewAuthHandler(authService)

	router.POST("/user", authHandler.Register) // 新增

	v1 := router.Group("/api/v1")
	{
		users := v1.Group("/users")
		{
			users.POST("", authHandler.Register)
		}
	}

	return router
}
