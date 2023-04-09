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

func (s *Service) registerServer() {
	// grpcServer := grpcstubs.GRPCServer()

	//
	// grpcEndpoints := append(s.Config.OldGRPCPorts, s.Config.GrpcServerEndpoint)
	// grpcstubs.GRPCServe(grpcServer, grpcEndpoints)
	//
	// httpEndpoints := append(s.Config.OldHTTPPorts, s.Config.HTTPServerEndpoint)
	// grpcstubs.HTTPServe(s.Config, httpEndpoints, registers())

	// s.grpcServer = grpcServer
}

func (s *Service) Close() error {
	// s.grpcServer.GracefulStop()
	return s.Store.Close()
}
