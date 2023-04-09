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
	pwd, _ := os.Getwd()
	serviceName := ""
	if serviceName == "" {
		panic("serviceName is empty")
	}
	cfg := &config.Config{
		ServiceName:    serviceName,
		Debug:          false,
		LogLevel:       "warn",
		DefaultTimeout: 1 * time.Second,
		Migration: &config.Migration{
			Driver: "sqlite3",
			Name:   "migration",
			Path:   fmt.Sprintf("/data/apps/%s/migrations/sqlite3", serviceName),
		},
		DB: &config.DB{
			Driver: "sqlite3",
			DSN:    fmt.Sprintf("/data/apps/%s/%s.db?_journal_mode=WAL", serviceName, serviceName),
		},
		Redis: &config.Redis{
			RedisMode: "redis-server",
			RedisServer: config.RedisServer{
				Address:  "127.0.0.1:6379",
				Password: "",
			},
			RedisSentinel: config.RedisSentinel{
				Address: []string{
					"127.0.0.1:26379",
				},
				Password:   "",
				MasterName: "master",
			},
		},
	}
	// 生产，默认配置
	cfgBytes, err := json.Marshal(cfg)
	if err != nil {
		panic(err)
	}
	var out bytes.Buffer
	json.Indent(&out, cfgBytes, "", "\t")
	os.WriteFile(pwd+"/config/config.json", out.Bytes(), 0755)

	cfgDev := &config.Config{
		ServiceName:    serviceName,
		Debug:          false,
		LogLevel:       "warn",
		DefaultTimeout: 1 * time.Second,
		Migration: &config.Migration{
			Driver: "sqlite3",
			Name:   "migration",
			Path:   fmt.Sprintf("/data/apps/%s/migrations/sqlite3", serviceName),
		},
		DB: &config.DB{
			Driver: "sqlite3",
			DSN:    fmt.Sprintf("/data/apps/%s/%s.db?_journal_mode=WAL", serviceName, serviceName),
		},
		Redis: &config.Redis{
			RedisMode: "redis-server",
			RedisServer: config.RedisServer{
				Address:  "127.0.0.1:6379",
				Password: "",
			},
			RedisSentinel: config.RedisSentinel{
				Address: []string{
					"127.0.0.1:26379",
				},
				Password:   "",
				MasterName: "master",
			},
		},
	}
	// 开发，测试配置
	cfgDevBytes, err := json.Marshal(cfgDev)
	if err != nil {
		panic(err)
	}
	var debugOut bytes.Buffer
	json.Indent(&debugOut, cfgDevBytes, "", "\t")
	os.WriteFile(pwd+"/config/config_dev.json", debugOut.Bytes(), 0755)
}
