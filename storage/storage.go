package storage

import (
	"context"

	"github.com/go-redis/redis/v8"
	"github.com/jmoiron/sqlx"
	"github.com/jony4/go-template/components/migration"
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
	}
	switch cfg.DB.Driver {
	case "sqlite3":
		sqlite3DB, err := sqlx.Connect("sqlite3", cfg.DB.DSN)
		if err != nil {
			log.Fatalf("[NewSQLite3Client] err: %v", err)
			return nil, err
		}
		s.SQLite3 = sqlite3DB

		// 迁移 sql
		if err := migration.NewEngine(cfg.Migration.Driver).MigrationUp(cfg.Migration.Name, cfg.Migration.Path, sqlite3DB); err != nil {
			return nil, err
		}
	default:
		panic("unsupported db config driver")
	}

	switch cfg.Redis.RedisMode {
	case "redis-server", "redis_server":
		s.RedisDB = redis.NewClient(&redis.Options{
			Addr:     cfg.Redis.RedisServer.Address,
			Password: cfg.Redis.RedisServer.Password, // no password set
			DB:       0,                              // use default DB
		})
	case "redis-sentinel", "redis_sentinel":
		s.RedisDB = redis.NewFailoverClient(&redis.FailoverOptions{
			MasterName:    cfg.Redis.RedisSentinel.MasterName,
			Password:      cfg.Redis.RedisSentinel.Password,
			SentinelAddrs: cfg.Redis.RedisSentinel.Address,
		})
	default:
		panic("unsupported redis config mode")
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

	if s.cfg.Redis.RedisMode != "" {
		// check redis
		if err := s.RedisDB.Ping(ctx).Err(); err != nil {
			return err
		}
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
