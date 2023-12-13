package service

import (
	"fmt"
	"net/http"

	"github.com/jony4/go-template/config"
	"github.com/jony4/go-template/storage"
	"github.com/labstack/echo/v5"
	"github.com/pocketbase/pocketbase"
	"github.com/pocketbase/pocketbase/core"
)

type Service struct {
	Config *config.Config
	Store  *storage.Storage
}

func NewService(cfg *config.Config, app *pocketbase.PocketBase) (*Service, error) {
	srv := &Service{
		Config: cfg,
	}
	// 初始化存储
	store, err := storage.NewStorage(cfg)
	if err != nil {
		return nil, fmt.Errorf("storage.NewStorage(cfg) %v", err)
	}
	srv.Store = store

	app.OnBeforeServe().Add(func(e *core.ServeEvent) error {

		api := e.Router.Group("/api")
		{
			api.Any("/hello", srv.Hello)
		}

		return nil
	})

	return srv, nil
}

func (s *Service) Close() error {
	return s.Store.Close()
}

func (s *Service) Hello(c echo.Context) error {
	return c.JSON(http.StatusOK, map[string]interface{}{
		"message": "hello world",
	})
}
