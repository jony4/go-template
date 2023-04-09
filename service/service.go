package service

import (
	"fmt"

	"github.com/jony4/go-template/config"
	"github.com/jony4/go-template/storage"
)

type Service struct {
	Config *config.Config
	Store  *storage.Storage
}

func NewService(cfg *config.Config) (*Service, error) {
	srv := &Service{
		Config: cfg,
	}
	// 初始化存储
	store, err := storage.NewStorage(cfg)
	if err != nil {
		return nil, fmt.Errorf("storage.NewStorage(cfg) %v", err)
	}
	srv.Store = store

	return srv, nil
}

func (s *Service) Close() error {
	return s.Store.Close()
}
