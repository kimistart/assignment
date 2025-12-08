package configs

const (
	// ProjectName 项目名称
	ProjectName = "go-gin-blog"

	// ProjectAccessLogFile 项目访问日志存放文件
	ProjectAccessLogFile = "./logs/" + ProjectName + "-access.log"

	// ProjectCronLogFile 项目后台任务日志存放文件
	ProjectCronLogFile = "./logs/" + ProjectName + "-cron.log"

	//秘钥
	securityKey = "qkhPAGA13HocW3GAEWwb"
)
