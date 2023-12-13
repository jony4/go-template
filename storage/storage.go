package storage

import (
	"context"

	"github.com/go-redis/redis/v8"
	"github.com/jony4/go-template/config"
	_ "github.com/mattn/go-sqlite3"
)

type Storage struct {
	cfg *config.Config

	RedisDB *redis.Client
}

func NewStorage(cfg *config.Config) (*Storage, error) {
	s := &Storage{
		cfg: cfg,
		RedisDB: redis.NewClient(&redis.Options{
			Addr:     cfg.Redis.Address,
			Password: cfg.Redis.Password, // no password set
			DB:       0,                  // use default DB
		}),
	}

	if err := s.healthCheck(); err != nil {
		return nil, err
	}

	return s, nil
}

// 启动时健康检查
func (s *Storage) healthCheck() error {
	ctx, cancel := context.WithTimeout(context.Background(), s.cfg.DefaultTimeout)
	defer cancel()

	// check redis
	if err := s.RedisDB.Ping(ctx).Err(); err != nil {
		return err
	}

	return nil
}

func (s *Storage) Close() error {

	return s.RedisDB.Close()
}
