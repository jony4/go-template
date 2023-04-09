package main

import (
	"flag"
	"os"
	"os/signal"

	"github.com/jony4/go-template/components/version"
	"github.com/jony4/go-template/components/xlog"
	"github.com/jony4/go-template/config"
	"github.com/jony4/go-template/service"
	log "github.com/sirupsen/logrus"
)

var (
	printVersion bool
	configPath   string
)

func main() {
	pwd, _ := os.Getwd()
	flag.BoolVar(&printVersion, "version", false, "print version of this build")
	flag.StringVar(&configPath, "config", pwd+"/config/config.json", "config file path of this project")
	flag.Parse()
	// print version
	if printVersion {
		version.PrintFullVersionInfo()
		return
	}

	// config
	cfg, err := config.LoadFromJSONFile(configPath)
	if err != nil {
		log.Fatal("config.LoadFromJSONFile", err)
	}

	xlog.InitLog(cfg.LogLevel)

	// service
	srv, err := service.NewService(cfg)
	if err != nil {
		log.Fatal("NewService err:", err)
	}

	// waiting signal
	sc := make(chan os.Signal, 1)
	signal.Notify(sc, os.Interrupt)
	sig := <-sc

	// close all
	log.Warnf("nebula-bizapp-engine-service system exit by received signal: %s, err: %v", sig.String(), srv.Close())
}
