package config

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"
)

// hi，配置文件生成请移步到 devops/config 目录！

type Config struct {
	// 基础配置
	ServiceName    string        `json:"service_name"`
	Debug          bool          `json:"debug"`
	LogLevel       string        `json:"log_level"`
	DefaultTimeout time.Duration `json:"default_timeout"`
	// 迁移相关
	Migration *Migration `json:"migration"`
	// 通用存储、消息队列等
	DB    *DB    `json:"db"`
	Redis *Redis `json:"redis"`
	// 外部依赖服务的 endpoint
	GrpcServerEndpoint *Endpoint `json:"grpc_server_endpoint"`
	HTTPServerEndpoint *Endpoint `json:"http_server_endpoint"`
}

// LoadFromJSONFile JSON文件解析
func LoadFromJSONFile(path string) (*Config, error) {
	var cfg Config
	content, err := os.ReadFile(filepath.Clean(path))
	if err != nil {
		return nil, fmt.Errorf("read config file failed: %v", err)
	}
	if err := json.Unmarshal(content, &cfg); err != nil {
		return nil, fmt.Errorf("unmarshal json failed: %v", err)
	}
	return &cfg, nil
}

type Migration struct {
	Driver string `json:"driver"`
	Name   string `json:"name"`
	Path   string `json:"path"`
}

type DB struct {
	Driver string `json:"driver"`
	DSN    string `json:"dsn"`
}

type Redis struct {
	RedisMode     string        `json:"redis_mode"`
	RedisServer   RedisServer   `json:"redis_server"`
	RedisSentinel RedisSentinel `json:"redis_sentinel"`
}

type RedisServer struct {
	Address  string `json:"address"`
	Password string `json:"password"`
}

type RedisSentinel struct {
	Address    []string `json:"address"`
	Password   string   `json:"password"`
	MasterName string   `json:"master_name"`
}

// Endpoint 相关配置
type Endpoint struct {
	Name     string `json:"name"`
	Address  string `json:"address"`
	Port     uint16 `json:"port"`
	UserName string `json:"username"`
	Password string `json:"password"`
}

// Endpoint string 格式
func (e *Endpoint) String() string {
	return fmt.Sprintf("%v:%v", e.Address, e.Port)
}
