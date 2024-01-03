package main

import (
	"os"

	"github.com/jony4/go-template/components/version"
	"github.com/jony4/go-template/components/xlog"
	"github.com/jony4/go-template/config"
	_ "github.com/jony4/go-template/migrations"
	"github.com/jony4/go-template/service"
	"github.com/pocketbase/pocketbase"
	"github.com/pocketbase/pocketbase/plugins/migratecmd"
	log "github.com/sirupsen/logrus"
)

func main() {
	var (
		pwd, _     = os.Getwd()
		configPath = os.Getenv("CONFIG_PATH")
		dataDir    = os.Getenv("DATA_DIR")
	)

	if configPath == "" {
		configPath = pwd + "/config/config.json"
	}
	if dataDir == "" {
		dataDir = pwd + "/pb_data"
	}

	app := pocketbase.NewWithConfig(pocketbase.Config{
		DefaultDataDir: dataDir,
	})

	migratecmd.MustRegister(app, app.RootCmd, migratecmd.Config{
		Automigrate: true, // auto creates migration files when making collection changes
	})

	// config
	cfg, err := config.LoadFromJSONFile(configPath)
	if err != nil {
		log.Fatal("config.LoadFromJSONFile", err)
	}
	xlog.InitLog(cfg.LogLevel)

	// service
	if _, err = service.NewService(cfg, app); err != nil {
		log.Fatal("NewService err:", err)
	}

	version.PrintFullVersionInfo()

	if err := app.Start(); err != nil {
		log.Fatal(err)
	}
}
