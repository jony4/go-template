package storage

import (
	"context"

	"github.com/go-redis/redis/v8"
	"github.com/jmoiron/sqlx"
	"github.com/jony4/go-template/config"
	_ "github.com/mattn/go-sqlite3"
	log "github.com/sirupsen/logrus"
)

type Storage struct {
	cfg *config.Config

	SQLite3 *sqlx.DB
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
	switch cfg.DB.Driver {
	case "sqlite3":
		sqlite3DB, err := sqlx.Connect("sqlite3", cfg.DB.DSN)
		if err != nil {
			log.Fatalf("[NewSQLite3Client] err: %v", err)
			return nil, err
		}
		s.SQLite3 = sqlite3DB
	default:
		panic("unsupported db config driver")
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

	switch s.cfg.DB.Driver {
	case "sqlite3":
		// check sqlite3
		if err := s.SQLite3.Ping(); err != nil {
			return err
		}
	}

	// check redis
	if err := s.RedisDB.Ping(ctx).Err(); err != nil {
		return err
	}

	return nil
}

func (s *Storage) Close() error {
	switch s.cfg.DB.Driver {
	case "sqlite3":
		return s.SQLite3.Close()
	default:
	}
	return s.RedisDB.Close()
}
