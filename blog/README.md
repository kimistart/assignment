# blog-system
```
博客系统后端（gin & gorm）
```

## 概要
```
使用 Go 语言结合 Gin 框架和 GORM 库开发的个人博客系统的后端，实现博客文章的基本管理功能。
```

## 运行环境
```
Go 1.24.11
MySQL
```

## 仓库结构（关键目录）

```
blog
├── go.mod
├── go.sum
├── main.go
├── README.md
├── 目录树.txt
├── cmd
│   └── migrate.go
├── configs
│   └── constants.go
├── internal
│   ├── handlers
│   │   ├── auth_handler.go
│   │   ├── comm_handler.go
│   │   └── post_handler.go
│   ├── middleware
│   │   └── middleware.go
│   ├── models
│   │   └── models.go
│   ├── repository
│   │   └── db_mysql
│   │       └── db_mysql.go
│   ├── router
│   │   └── router.go
│   └── services
│       ├── auth_service.go
│       ├── comm_service.go
│       └── post_service.go
├── pkg
│   ├── env
│   │   └── env.go
│   └── timeutil
│       └── timeutil.go
└── test
    ├── 创建文章.png
    ├── 拉取评论.png
    ├── 更新文章.png
    ├── 查询文章列表.png
    ├── 注册.png
    ├── 添加评论.png
    ├── 登录.png
    └── 软删除文章.png
```
## 配置（config.yaml）
# 项目根目录config.yaml示例：
```
system:
  port: ":9095"
mysql:
  host: "127.0.0.1"
  dbname: "blog"
  username: "root"
  password: "123456"
```
## 依赖安装 & 编译
```
1. 创建数据库 blog
2. 进入cmd文件夹执行  go run main 创建表
3. 进入blog文件夹执行 go run main.go 启动服务
```