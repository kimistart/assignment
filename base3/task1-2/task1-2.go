package main

/*编写一个事务，实现从账户 A 向账户 B 转账 100 元的操作。
在事务中，需要先检查账户 A 的余额是否足够，如果足够则从账户 A 扣除 100 元，向账户 B 增加 100 元，并在 transactions 表中记录该笔转账信息。
如果余额不足，则回滚事务。 */

import (
	"errors"
	"fmt"
	"log"
	"time"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"

	"github.com/shopspring/decimal"
)

type Account struct {
	ID      int
	Balance decimal.Decimal
}

type Transaction struct {
	ID              int
	From_account_id string
	To_account_id   string
	Amount          decimal.Decimal
	CreateAt        time.Time
}

func Transfer(fromID string, toID string, amount decimal.Decimal) error {

	var db *gorm.DB
	dsn := "root:123456@tcp(192.168.111.109:3306)/go_test?charset=utf8mb4&parseTime=True&loc=Local"
	var err error
	db, err = gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("failed to connect database")
	}
	println("Gorm连接数据库成功！")

	//开启事务
	tx := db.Begin()
	if tx.Error != nil {
		return tx.Error
	}

	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// 查询转出账户的数据库信息
	var fromAcc Account
	if err := tx.Set("gorm:query_option", "FOR UPDATE").First(&fromAcc, fromID).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("转出账户不存在:%v", err)
	}

	// 检查余额
	if fromAcc.Balance.LessThan(amount) {
		tx.Rollback()
		return errors.New("账户余额不足")
	}

	// 从账户 A 扣除 100 元
	if err := tx.Model(&fromAcc).Update("balance", gorm.Expr("balance - ?", amount)).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("扣除余额失败:%v", err)
	}

	// 查询转入账户的数据库信息
	var toAcc Account
	if err := tx.Set("gorm:query_option", "FOR UPDATE").First(&toAcc, toID).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("转入账户不存在:%v", err)
	}
	// 向账户 B 增加 100 元
	if err := tx.Model(&toAcc).Update("balance", gorm.Expr("balance + ?", amount)).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("增加余额失败:%v", err)
	}

	// 在 transactions 表中记录该笔转账信息
	trans := Transaction{
		From_account_id: fromID,
		To_account_id:   toID,
		Amount:          amount,
	}
	if err := tx.Create(&trans).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("记录转账信息失败:%v", err)
	}

	return tx.Commit().Error
}

func main() {

	fromID := "1"
	toID := "2"

	amount := decimal.NewFromInt(100)

	if err := Transfer(fromID, toID, amount); err != nil {
		log.Println("转账失败", err)
	} else {
		log.Println("转账成功!")
	}
}
