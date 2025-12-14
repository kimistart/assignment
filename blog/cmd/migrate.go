package main

import (
	"blog/internal/repository/db_mysql"
	"log"

	"blog/internal/models"
)

func main() {

	db_mysql.New()

	defer func() {
		if err := db_mysql.Close(); err != nil {
			log.Println("关闭数据库连接时出错:", err)
		} else {
			log.Println("数据库连接已关闭")
		}
	}()

	db_mysql.DB.AutoMigrate(&models.User{})
	db_mysql.DB.AutoMigrate(&models.Post{})
	db_mysql.DB.AutoMigrate(&models.Comment{})

	log.Println("数据库表创建/修复完成")
}
