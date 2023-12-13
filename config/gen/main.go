package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"time"

	"github.com/jony4/go-template/config"
)

func main() {
	var (
		pwd, _      = os.Getwd()
		dirName     = "/data/apps"
		serviceName = "go-template"
	)

	// 生产，默认配置
	cfg := &config.Config{
		ServiceName:    serviceName,
		Debug:          false,
		LogLevel:       "warn",
		DefaultTimeout: 1 * time.Second,
		DB: &config.DB{
			Driver: "sqlite3",
			DSN:    fmt.Sprintf("%s/%s/%s.db?_journal_mode=WAL", dirName, serviceName, serviceName),
		},
		Redis: &config.RedisServer{
			Address:  "127.0.0.1:6379",
			Password: "",
		},
	}
	cfgBytes, err := json.Marshal(cfg)
	if err != nil {
		panic(err)
	}
	var out bytes.Buffer
	json.Indent(&out, cfgBytes, "", "\t")
	os.WriteFile(pwd+"/config/config.json", out.Bytes(), 0755)

	serviceName += "-dev"
	// 开发，测试配置
	cfgDev := &config.Config{
		ServiceName:    serviceName,
		Debug:          true,
		LogLevel:       "debug",
		DefaultTimeout: 1 * time.Second,
		DB: &config.DB{
			Driver: "sqlite3",
			DSN:    pwd + fmt.Sprintf("/%s.db?_journal_mode=WAL", serviceName),
		},
		Redis: &config.RedisServer{
			Address:  "127.0.0.1:6379",
			Password: "",
		},
	}
	cfgDevBytes, err := json.Marshal(cfgDev)
	if err != nil {
		panic(err)
	}
	var debugOut bytes.Buffer
	json.Indent(&debugOut, cfgDevBytes, "", "\t")
	os.WriteFile(pwd+"/config/config_dev.json", debugOut.Bytes(), 0755)
}
