-- +migrate Up

CREATE TABLE "public"."bizapp" (
    "id" SERIAL,
    "name" VARCHAR(128) NULL DEFAULT ''::character varying ,
    "version" VARCHAR(255) NULL DEFAULT ''::character varying ,
    "state" INTEGER NULL DEFAULT 0 ,
    "applets" JSON NULL,
    "create_time" TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ,
    "update_time" TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ,
    CONSTRAINT "bizapp_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."bizapp_state" (
    "id" TEXT NOT NULL,
    "op_version" INTEGER NOT NULL,
    "lock_version" INTEGER NOT NULL,
    "locked" BOOLEAN NOT NULL,
    "source" TEXT NOT NULL,
    "created_at" TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ,
    "updated_at" TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ,
    CONSTRAINT "biz_cfg_state_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."nebula_bizapp_task_applet_meta" (
    "id" SERIAL,
    "biz_app_name" VARCHAR(100) NOT NULL DEFAULT ''::character varying ,
    "biz_app_version" INTEGER NOT NULL DEFAULT 0 ,
    "app_name" VARCHAR(100) NOT NULL DEFAULT ''::character varying ,
    "app_version" INTEGER NOT NULL DEFAULT 0 ,
    "app_url" VARCHAR(100) NOT NULL DEFAULT ''::character varying ,
    "st_event_type" VARCHAR(100) NOT NULL DEFAULT ''::character varying ,
    "detect_type" VARCHAR(100) NOT NULL DEFAULT ''::character varying ,
    "deleted" INTEGER NOT NULL DEFAULT 0 ,
    "create_time" BIGINT NOT NULL DEFAULT 0 ,
    "update_time" BIGINT NOT NULL DEFAULT 0 ,
    CONSTRAINT "nebula_bizapp_task_applet_meta_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."nebula_bizapp_task_engine_rel" (
    "id" SERIAL,
    "task_id" INTEGER NOT NULL DEFAULT 0 ,
    "tms_id" VARCHAR(100) NOT NULL DEFAULT ''::character varying ,
    "rule_id" VARCHAR(100) NOT NULL DEFAULT ''::character varying ,
    CONSTRAINT "nebula_bizapp_task_engine_rel_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."nebula_bizapp_task_portrait_db_rel" (
    "id" SERIAL,
    "task_id" INTEGER NOT NULL DEFAULT 0 ,
    "portrait_db_id" VARCHAR(100) NOT NULL DEFAULT ''::character varying ,
    CONSTRAINT "nebula_bizapp_task_portrait_db_rel_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."nebula_bizapp_task_major_quota_info" (
    "id" SERIAL,
    "identifier_id" VARCHAR(100) NOT NULL DEFAULT ''::character varying ,
    "resolution" INTEGER NOT NULL DEFAULT 0 ,
    "label" INTEGER NOT NULL DEFAULT 0 ,
    "state" INTEGER NOT NULL DEFAULT 1 ,
    "quota_used" INTEGER NOT NULL DEFAULT 0 ,
    CONSTRAINT "nebula_bizapp_task_major_quota_info_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."nebula_bizapp_task_algo_quota_info" (
    "id" SERIAL,
    "resolution" INTEGER NOT NULL DEFAULT 0 ,
    "state" INTEGER NOT NULL DEFAULT 1 ,
    "quota_used" INTEGER NOT NULL DEFAULT 0 ,
    "version" INTEGER NOT NULL DEFAULT 0 ,
    "merge_id" VARCHAR(100) NOT NULL DEFAULT ''::character varying ,
    "identifier_id" VARCHAR(100) NOT NULL DEFAULT ''::character varying ,
    "sub_device_id" VARCHAR(100) NOT NULL DEFAULT ''::character varying ,
    "app_name" VARCHAR(100) NOT NULL DEFAULT ''::character varying ,
    "task_type" VARCHAR(50) NOT NULL DEFAULT ''::character varying ,
    "detect_type" VARCHAR(100) NOT NULL DEFAULT ''::character varying ,
    CONSTRAINT "nebula_bizapp_task_algo_quota_info_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."nebula_bizapp_task" (
    "id" SERIAL,
    "identifier_id" VARCHAR(100) NOT NULL DEFAULT ''::character varying ,
    "app_name" VARCHAR(100) NOT NULL DEFAULT ''::character varying ,
    "task_type" VARCHAR(50) NOT NULL DEFAULT ''::character varying ,
    "name" VARCHAR(100) NOT NULL DEFAULT ''::character varying ,
    "sub_device_id" VARCHAR(100) NOT NULL DEFAULT ''::character varying ,
    "detect_type" VARCHAR(100) NOT NULL DEFAULT ''::character varying ,
    "active" INTEGER NOT NULL DEFAULT 1 ,
    "state" INTEGER NOT NULL DEFAULT 1 ,
    "engine_state" INTEGER NOT NULL DEFAULT 1 ,
    "stream_type" INTEGER NOT NULL DEFAULT 1 ,
    "support_merge" INTEGER NOT NULL DEFAULT 1 ,
    "schedule" TEXT NOT NULL DEFAULT ''::text ,
    "object_config" TEXT NOT NULL DEFAULT ''::text ,
    "extend_config" TEXT NOT NULL DEFAULT ''::text ,
    "dbs" TEXT NOT NULL DEFAULT ''::text ,
    "remark" VARCHAR(100) NOT NULL DEFAULT ''::character varying ,
    "deleted" INTEGER NOT NULL DEFAULT 0 ,
    "create_by" VARCHAR(100) NOT NULL DEFAULT 0 ,
    "create_time" BIGINT NOT NULL DEFAULT 0 ,
    "update_by" VARCHAR(100) NOT NULL DEFAULT 0 ,
    "update_time" BIGINT NOT NULL DEFAULT 0 ,
    "state_msg" VARCHAR(3000) NOT NULL DEFAULT ''::character varying ,
    "consumed_power" NUMERIC NOT NULL DEFAULT 0.0 ,
    "pu" INTEGER NOT NULL DEFAULT 0 ,
    "decimal_consumed_power" VARCHAR(3000) NOT NULL DEFAULT ''::character varying ,
    CONSTRAINT "nebula_bizapp_task_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."bizapp_info" (
    "id" INTEGER NOT NULL,
    "biz_app_name" VARCHAR(128) NOT NULL DEFAULT ''::character varying ,
    "biz_app_version" INTEGER NOT NULL DEFAULT 0 ,
    "applet_infos" JSONB NOT NULL DEFAULT '{}'::jsonb ,
    "create_time" TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ,
    "update_time" TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ,
    CONSTRAINT "bizapp_info_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "public"."record" (
    "auto_id" INTEGER NOT NULL,
    "id" CHARACTER(36) NOT NULL DEFAULT ''::bpchar ,
    "event_id" VARCHAR(200) NOT NULL DEFAULT ''::character varying ,
    "object_id" VARCHAR(200) NOT NULL DEFAULT ''::character varying ,
    "record_type" VARCHAR(200) NOT NULL DEFAULT ''::character varying ,
    "portrait_image_url" VARCHAR(255) NOT NULL DEFAULT ''::character varying ,
    "panoramic_image_url" VARCHAR(255) NOT NULL DEFAULT ''::character varying ,
    "portrait_image_location" JSONB NOT NULL DEFAULT '{}'::jsonb ,
    "captured_time" BIGINT NOT NULL DEFAULT 0 ,
    "received_time" BIGINT NOT NULL DEFAULT 0 ,
    "create_time" BIGINT NOT NULL DEFAULT 0 ,
    "sub_device_id" VARCHAR(200) NOT NULL DEFAULT ''::character varying ,
    "sub_device_name" VARCHAR(200) NOT NULL DEFAULT ''::character varying ,
    "task_id" VARCHAR(200) NOT NULL DEFAULT ''::character varying ,
    "task_name" VARCHAR(200) NOT NULL DEFAULT ''::character varying ,
    "task_type" VARCHAR(200) NOT NULL DEFAULT ''::character varying ,
    "detect_type" VARCHAR(200) NOT NULL DEFAULT ''::character varying ,
    "roi" JSONB NOT NULL DEFAULT '{}'::jsonb ,
    "stacked" JSONB NOT NULL DEFAULT '{}'::jsonb ,
    "push_interval" INTEGER NOT NULL DEFAULT 0 ,
    "lib_info" JSONB NOT NULL DEFAULT '{}'::jsonb ,
    "attrs" JSONB NOT NULL DEFAULT '{}'::jsonb ,
    "applet" JSONB NOT NULL DEFAULT '{}'::jsonb ,
    "particular" JSONB NOT NULL DEFAULT '{}'::jsonb ,
    "applet_record_type" VARCHAR(100) NOT NULL DEFAULT ''::character varying ,
    "task_extra_info" JSONB NOT NULL DEFAULT '{}'::jsonb ,
    CONSTRAINT "record_pkey1" PRIMARY KEY ("auto_id")
);
CREATE TABLE IF NOT EXISTS bizapp_engine_config
(
    id SERIAL,
    config_name VARCHAR(255) NULL DEFAULT ''::character varying,
    config_value VARCHAR(255) NULL DEFAULT ''::character varying,
    create_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX "uk_name"
    ON "public"."bizapp_info" (
                               "biz_app_name" ASC
        );
CREATE INDEX "record_record_type_idx"
    ON "public"."record" (
                          "record_type" ASC
        );
CREATE INDEX "record_sub_device_id_idx"
    ON "public"."record" (
                          "sub_device_id" ASC
        );
CREATE INDEX "record_sub_device_name_idx"
    ON "public"."record" (
                          "sub_device_name" ASC
        );
CREATE INDEX "record_task_id_idx"
    ON "public"."record" (
                          "task_id" ASC
        );
CREATE INDEX "record_task_name_idx"
    ON "public"."record" (
                          "task_name" ASC
        );
CREATE INDEX "record_task_type_idx"
    ON "public"."record" (
                          "task_type" ASC
        );
CREATE INDEX "record_detect_type_idx"
    ON "public"."record" (
                          "detect_type" ASC
        );
CREATE INDEX "record_applet_record_type_idx"
    ON "public"."record" (
                          "applet_record_type" ASC
        );
CREATE UNIQUE INDEX "record_id_idx"
    ON "public"."record" (
                          "id" ASC
        );
CREATE INDEX "record_captured_time_idx"
    ON "public"."record" (
                          "captured_time" ASC
        );


-- +migrate Down

DROP TABLE IF EXISTS "public"."bizapp";
DROP TABLE IF EXISTS "public"."bizapp_info";
DROP TABLE IF EXISTS "public"."bizapp_state";
DROP TABLE IF EXISTS "public"."nebula_bizapp_task";
DROP TABLE IF EXISTS "public"."nebula_bizapp_task_applet_meta";
DROP TABLE IF EXISTS "public"."nebula_bizapp_task_algo_quota_info";
DROP TABLE IF EXISTS "public"."nebula_bizapp_task_engine_rel";
DROP TABLE IF EXISTS "public"."nebula_bizapp_task_major_quota_info";
DROP TABLE IF EXISTS "public"."nebula_bizapp_task_portrait_db_rel";
DROP TABLE IF EXISTS "public"."record";
DROP TABLE IF EXISTS "public"."bizapp_engine_config";
