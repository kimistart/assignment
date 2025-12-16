package middleware

import (
	"blog/configs"
	"blog/internal/models"
	"blog/internal/repository/db_mysql"
	"bytes"
	"io"
	"log"
	"net/http"
	"strings"

	"github.com/dgrijalva/jwt-go"
	"github.com/gin-gonic/gin"
)

func JWTAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 1. 从 Header 获取 token
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			// 如果没有 response 包，直接返回 JSON
			c.JSON(401, gin.H{
				"code": 401,
				"msg":  "未登录或非法访问，请登录",
			})
			c.Abort()
			return
		}

		// 2. 检查 token 格式 (Bearer token)
		parts := strings.SplitN(authHeader, " ", 2)
		if !(len(parts) == 2 && parts[0] == "Bearer") {
			c.JSON(401, gin.H{
				"code": 401,
				"msg":  "token 格式错误，应为 'Bearer {token}'",
			})
			c.Abort()
			return
		}

		token := parts[1]

		// 3. 验证 token
		claims, err := parseToken(token)
		if err != nil {
			c.JSON(401, gin.H{
				"code": 401,
				"msg":  "token 无效或已过期",
			})
			c.Abort()
			return
		}

		// 4. 将用户信息存入上下文，供后续处理使用
		if id, ok := claims["id"].(float64); ok {
			c.Set("user_id", uint(id))
		}
		if username, ok := claims["username"].(string); ok {
			c.Set("username", username)
		}

		log.Println("middleware:登录校验完成~")

		// 继续处理请求
		c.Next()
	}
}

func parseToken(tokenString string) (jwt.MapClaims, error) {

	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		return []byte(configs.SecurityKey), nil
	})
	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
		return claims, nil
	}

	return nil, jwt.NewValidationError("invalid token", jwt.ValidationErrorClaimsInvalid)
}

func IsAuthor() gin.HandlerFunc {
	return func(ctx *gin.Context) {

		user_id, _ := ctx.Get("user_id")

		log.Println("user_id:", user_id)

		body, _ := io.ReadAll(ctx.Request.Body)

		ctx.Request.Body = io.NopCloser(bytes.NewBuffer(body))

		var post models.Post

		if err := ctx.ShouldBindJSON(&post); err != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{
				"err": "请求参数错误" + err.Error(),
			})
			ctx.Abort()
			return
		}

		log.Println("post_id:", post.ID)

		result := db_mysql.DB.First(&post, post.ID)
		if result.Error != nil {
			ctx.JSON(404, gin.H{"error": "文章不存在"})
			ctx.Abort()
			return
		}

		userId, _ := user_id.(uint)

		if post.UserID != userId {
			ctx.JSON(http.StatusForbidden, gin.H{
				"error": "无权操作此文章",
			})
			ctx.Abort()
			return
		}

		ctx.Request.Body = io.NopCloser(bytes.NewBuffer(body))

		ctx.Next()

	}
}
