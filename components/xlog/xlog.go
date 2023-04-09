package xlog

import (
	"github.com/onrik/logrus/filename"
	log "github.com/sirupsen/logrus"
)

func InitLog(level string) {
	logLevel, err := log.ParseLevel(level)
	if err != nil {
		logLevel = log.TraceLevel
	}
	log.SetLevel(logLevel)
	log.AddHook(filename.NewHook())
	log.SetReportCaller(true)
	log.SetFormatter(
		&log.TextFormatter{
			ForceColors:     true,
			FullTimestamp:   true,
			TimestampFormat: "01-02T15:04:05.999999",
		},
	)
}
