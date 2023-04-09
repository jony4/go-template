package migration

import (
	"github.com/jmoiron/sqlx"
	migrate "github.com/rubenv/sql-migrate"
	log "github.com/sirupsen/logrus"
)

type Engine struct {
	DriverName string `json:"driver_name"`
}

func NewEngine(driverName string) *Engine {
	return &Engine{DriverName: driverName}
}

// MigrationUp MigrationUp
/*
 * migrationInfoTable: 非业务表名，用migration_db名 来定义，每个db文件都需要一个migrationInfoTable，用于migration保存它自己的信息，不能和业务表名重复
 * migrationSource: sql脚本路径，每个db的升级回退sql都得单独文件夹。例如：/face/20211201160000_face_record_db.sql，sql命名按照：20211201160000_name.sql规则
 * db: 创建的db句柄
 */
func (engine *Engine) MigrationUp(migrationInfoTable, migrationSource string, db *sqlx.DB) error {
	migrate.SetTable(migrationInfoTable)
	migrations := &migrate.FileMigrationSource{
		Dir: migrationSource,
	}
	nf, err := migrate.ExecMax(db.DB, engine.DriverName, migrations, migrate.Up, 0)
	if err != nil {
		log.Errorf("[MigrationUp] migrationSource: %s, err: %v", migrationSource, err)
		return err
	}
	if nf > 0 {
		log.Infof("[MigrationUp] migrationSource: %s success, version: %v", migrationSource, nf)
	} else {
		log.Infof("[MigrationUp] migrationSource: %s already been latest version", migrationSource)
	}

	return nil
}

func (engine *Engine) MigrationDown(migrationSource string, db *sqlx.DB) error {
	migrations := &migrate.FileMigrationSource{
		Dir: migrationSource,
	}
	n, err := migrate.ExecMax(db.DB, engine.DriverName, migrations, migrate.Down, 1)
	if err != nil {
		log.Errorf("[MigrateDown] Can't execute migrationSource: %s, download err: %s", migrationSource, err.Error())
		return err
	}
	log.Infof("[MigrateDown] migrationSource: %s, download successfully and downgrade version: %v", migrationSource, n)

	return nil
}
