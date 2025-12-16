package db_mysql

import (
	"database/sql"
	"log"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

var DB *gorm.DB
var sqlDB *sql.DB

func New() {

	// dsn := "root:123456@tcp(192.168.111.109:3306)/blog?charset=utf8mb4&parseTime=True&loc=Local"
	dsn := "root:123456@tcp(127.0.0.1:3306)/blog?charset=utf8mb4&parseTime=True&loc=Local"
	var err error
	DB, err = gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("failed to connect database")
	}

	sqlDB, err = DB.DB()
	if err != nil {
		log.Fatal("failed to get sql.DB:", err)
	}

	log.Println("Gorm连接数据库成功！")
}

func Close() error {
	if sqlDB != nil {
		return sqlDB.Close()
	}
	return nil
}
