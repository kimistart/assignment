package router

import (
	"blog/internal/handlers"
	"blog/internal/middleware"
	"blog/internal/services"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func SetupRouter(db *gorm.DB) *gin.Engine {

	router := gin.Default()

	authService := services.NewAuthService(db)
	authHandler := handlers.NewAuthHandler(authService)

	postService := services.NewPostService(db)
	postHandler := handlers.NewPostHandler(postService)

	v1 := router.Group("/api/v1")
	{
		users := v1.Group("/users")
		{
			users.POST("", authHandler.Register)
			users.POST("/login", authHandler.Login)
		}
	}

	v2 := router.Group("/api/v2")
	{
		posts := v2.Group("/posts")
		{
			posts.POST("/create", middleware.JWTAuth(), postHandler.CreatePost)
		}
	}

	return router
}
