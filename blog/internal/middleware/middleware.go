package middleware

import (
	"blog/configs"
	"log"
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
