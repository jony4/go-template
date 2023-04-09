-- +migrate Up

CREATE TABLE IF NOT EXISTS "bizapp" (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    name         varchar(128) DEFAULT '',                   -- 'bizapp',
    version     varchar(255) DEFAULT '',                   -- 'bizapp版本号',
    state        INTEGER DEFAULT 0,                        -- 'bizapp的状态'
    applets     blob NULL DEFAULT '',                      -- 'applets信息'
    create_time  timestamp NULL DEFAULT CURRENT_TIMESTAMP,  -- '创建时间',
    update_time  timestamp NULL DEFAULT CURRENT_TIMESTAMP   -- '更新时间',
);

CREATE TABLE IF NOT EXISTS "nebula_bizapp_task_applet_meta" (
    "id"             INTEGER PRIMARY KEY AUTOINCREMENT,
    "biz_app_name"       varchar(100)    NOT NULL DEFAULT '',
    "biz_app_version"    INTEGER         NOT NULL DEFAULT 0,
    "app_name"       varchar(100)        NOT NULL DEFAULT '',
    "app_version"    INTEGER             NOT NULL DEFAULT 0,
    "app_url"        varchar(100)        NOT NULL DEFAULT '',
    "st_event_type"  varchar(100)        NOT NULL DEFAULT '',
    "detect_type"    varchar(100)        NOT NULL DEFAULT '',
    "stream_type"    INTEGER             NOT NULL DEFAULT 1,
    "deleted"        INTEGER             NOT NULL DEFAULT 0,
    "create_time"    BIGINT              NOT NULL DEFAULT 0,
    "update_time"    BIGINT              NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS "bizapp_state" (
  "id" TEXT PRIMARY KEY NOT NULL,
  "op_version" INTEGER NOT NULL,
  "lock_version" INTEGER NOT NULL,
  "locked" BOOLEAN NOT NULL,
  "source" TEXT NOT NULL,
  "created_at" TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ,
  "updated_at" TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS "nebula_bizapp_task" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "identifier_id" VARCHAR(100) NOT NULL DEFAULT '' ,
  "app_name" VARCHAR(100) NOT NULL DEFAULT '' ,
  "task_type" VARCHAR(50) NOT NULL DEFAULT '' ,
  "name" VARCHAR(100) NOT NULL DEFAULT '' ,
  "sub_device_id" VARCHAR(100) NOT NULL DEFAULT '' ,
  "detect_type" VARCHAR(100) NOT NULL DEFAULT '' ,
  "active" INTEGER NOT NULL DEFAULT 1 ,
  "state" INTEGER NOT NULL DEFAULT 1 ,
  "engine_state" INTEGER NOT NULL DEFAULT 1 ,
  "stream_type" INTEGER NOT NULL DEFAULT 1 ,
  "support_merge" INTEGER NOT NULL DEFAULT 1 ,
  "schedule" TEXT NOT NULL DEFAULT '' ,
  "object_config" TEXT NOT NULL DEFAULT '' ,
  "extend_config" TEXT NOT NULL DEFAULT '' ,
  "dbs" TEXT NOT NULL DEFAULT '' ,
  "remark" VARCHAR(100) NOT NULL DEFAULT '' ,
  "deleted" INTEGER NOT NULL DEFAULT 0 ,
  "create_by" VARCHAR(100) NOT NULL DEFAULT 0 ,
  "create_time" BIGINT NOT NULL DEFAULT 0 ,
  "update_by" VARCHAR(100) NOT NULL DEFAULT 0 ,
  "update_time" BIGINT NOT NULL DEFAULT 0 ,
  "state_msg" VARCHAR(3000) NOT NULL DEFAULT '' ,
  "consumed_power" NUMERIC NOT NULL DEFAULT 0.0 ,
  "pu" INTEGER NOT NULL DEFAULT 0 ,
  "decimal_consumed_power" VARCHAR(3000) NOT NULL DEFAULT ''
);
CREATE TABLE IF NOT EXISTS "nebula_bizapp_task_engine_rel" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "task_id" INTEGER NOT NULL DEFAULT 0 ,
  "tms_id" VARCHAR(100) NOT NULL DEFAULT '' ,
  "rule_id" VARCHAR(100) NOT NULL DEFAULT ''
);
CREATE TABLE IF NOT EXISTS "nebula_bizapp_task_portrait_db_rel" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "task_id" INTEGER NOT NULL DEFAULT 0 ,
  "portrait_db_id" VARCHAR(100) NOT NULL DEFAULT ''
);
CREATE TABLE IF NOT EXISTS "nebula_bizapp_task_major_quota_info" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "identifier_id" VARCHAR(100) NOT NULL DEFAULT '' ,
  "resolution" INTEGER NOT NULL DEFAULT 0 ,
  "label" INTEGER NOT NULL DEFAULT 0 ,
  "state" INTEGER NOT NULL DEFAULT 1 ,
  "quota_used" INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS "nebula_bizapp_task_algo_quota_info" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "resolution" INTEGER NOT NULL DEFAULT 0 ,
  "state" INTEGER NOT NULL DEFAULT 1 ,
  "quota_used" INTEGER NOT NULL DEFAULT 0 ,
  "version" INTEGER NOT NULL DEFAULT 0 ,
  "merge_id" VARCHAR(100) NOT NULL DEFAULT '' ,
  "identifier_id" VARCHAR(100) NOT NULL DEFAULT '' ,
  "sub_device_id" VARCHAR(100) NOT NULL DEFAULT '' ,
  "app_name" VARCHAR(100) NOT NULL DEFAULT '' ,
  "task_type" VARCHAR(50) NOT NULL DEFAULT '' ,
  "detect_type" VARCHAR(100) NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS bizapp_info
(
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,                                                      -- 'id',
    biz_app_name VARCHAR(128) NOT NULL UNIQUE DEFAULT '' CHECK( LENGTH(`biz_app_name`) <= 128 ),        -- 'bizapp名字',
    biz_app_version INTEGER NOT NULL DEFAULT 0,                                                         -- 'bizapp 版本',
    applet_infos JSONB NOT NULL DEFAULT '{}',                                                           -- 'applet信息',
    create_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,                                               -- '创建时间',
    update_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP                                                -- '更新时间',
);

CREATE TABLE IF NOT EXISTS record
(
    auto_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,                                                 -- 'id',
    id CHAR(36) NOT NULL UNIQUE DEFAULT '' CHECK( LENGTH(`id`) <= 36 ),
    event_id VARCHAR(200) not null default '' CHECK( LENGTH(`event_id`) <= 200 ),
    object_id VARCHAR(200) not null default '' CHECK( LENGTH(`object_id`) <= 200 ),
    record_type VARCHAR(200) not null default '' CHECK( LENGTH(`record_type`) <= 200 ),                 -- 告警类型
    portrait_image_url VARCHAR(255) not null default '' CHECK( LENGTH(`portrait_image_url`) <= 255 ),   -- 小图osg地址
    panoramic_image_url VARCHAR(255) not null default '' CHECK( LENGTH(`panoramic_image_url`) <= 255 ), -- 大图osg地址
    portrait_image_location JSONB NOT NULL DEFAULT '{}',                                                -- 小图在大图的位置,json,可直接取msc.output的portrait_image_location字段
    captured_time BIGINT NOT NULL DEFAULT 0,                                                            -- 图片实际抓拍时间,单位毫秒
    received_time BIGINT NOT NULL DEFAULT 0,                                                            -- 消息接收时间,单位毫秒
    create_time BIGINT NOT NULL DEFAULT 0,                                                              -- 入db时间,单位毫秒
    sub_device_id VARCHAR(200) NOT NULL DEFAULT '' CHECK( LENGTH(`sub_device_id`) <= 200 ),             -- #camera id
    sub_device_name VARCHAR(200) NOT NULL DEFAULT '' CHECK( LENGTH(`sub_device_name`) <= 200 ),         -- #camera name
    task_id VARCHAR(200) NOT NULL DEFAULT '' CHECK( LENGTH(`task_id`) <= 200 ),
    task_name VARCHAR(200) NOT NULL DEFAULT '' CHECK( LENGTH(`task_name`) <= 200 ),
    task_type VARCHAR(200) NOT NULL DEFAULT '' CHECK( LENGTH(`task_type`) <= 200 ),
    detect_type VARCHAR(200) NOT NULL DEFAULT '' CHECK( LENGTH(`detect_type`) <= 200 ),
    roi JSONB NOT NULL DEFAULT '{}',                                                                    -- 热区区域,json
    stacked JSONB NOT NULL DEFAULT '{}',                                                                -- 叠框,json,{"width","top","left","height"}
    push_interval INTEGER NOT NULL DEFAULT 0,                                                           -- tms告警推送间隔,单位秒
    lib_info JSONB NOT NULL DEFAULT '{}',                                                               -- 人像库信息,json,可为空
    attrs JSONB NOT NULL DEFAULT '{}',                                                                  -- 算法属性, json, 可为空
    applet JSONB NOT NULL DEFAULT '{}',                                                                 -- applet输出字段
    particular JSONB NOT NULL DEFAULT '{}',                                                             -- 业务自定义字段,json, 常用有data_type,view_info,roi_name
    applet_record_type VARCHAR(100) NOT NULL DEFAULT '' CHECK( LENGTH(`applet_record_type`) <= 100 ),   -- applet记录类型 alarm:告警, capture:抓拍
    task_extra_info JSONB NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS record_type_i ON record (record_type);
CREATE INDEX IF NOT EXISTS sub_device_id_i ON record (sub_device_id);
CREATE INDEX IF NOT EXISTS sub_device_name_i ON record (sub_device_name);
CREATE INDEX IF NOT EXISTS task_id_i ON record (task_id);
CREATE INDEX IF NOT EXISTS task_name_i ON record (task_name);
CREATE INDEX IF NOT EXISTS task_type_i ON record (task_type);
CREATE INDEX IF NOT EXISTS detect_type_i ON record (detect_type);
CREATE INDEX IF NOT EXISTS index_applet_record_type ON record (applet_record_type);
CREATE INDEX IF NOT EXISTS captured_time_i ON record (captured_time);

CREATE TABLE IF NOT EXISTS bizapp_engine_config
(
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,                                                      -- 'id',
    config_name VARCHAR(256) NOT NULL UNIQUE DEFAULT '' CHECK( LENGTH(`config_name`) <= 256 ),          -- '配置名称',
    config_value VARCHAR(256) NOT NULL DEFAULT '' CHECK( LENGTH(`config_name`) <= 256 ),                -- '配置值',
    create_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,                                               -- '创建时间',
    update_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP                                                -- '更新时间',
);

-- +migrate Down

DROP TABLE IF EXISTS "bizapp";
DROP TABLE IF EXISTS "bizapp_info";
DROP TABLE IF EXISTS "bizapp_state";
DROP TABLE IF EXISTS "nebula_bizapp_task";
DROP TABLE IF EXISTS "nebula_bizapp_task_applet_meta";
DROP TABLE IF EXISTS "nebula_bizapp_task_algo_quota_info";
DROP TABLE IF EXISTS "nebula_bizapp_task_engine_rel";
DROP TABLE IF EXISTS "nebula_bizapp_task_major_quota_info";
DROP TABLE IF EXISTS "nebula_bizapp_task_portrait_db_rel";
DROP TABLE IF EXISTS "record";
DROP TABLE IF EXISTS "bizapp_engine_config";
