########### 通用环境变量 begin #############
# 产品信息
PROJECT_GO = $(shell go list -m)
PROJECT_NAME = go-template
VERSION = 0.0.1

# git 仓库基本信息
BRANCH_NAME = $(shell git rev-parse --abbrev-ref HEAD)
BUILD_TS = $(shell TZ=UTC-8 date +"%Y-%m-%d %H:%M:%S")
COMMIT_ID = $(shell git rev-parse --short=8 HEAD)
CHANNEL := $(subst /,-,$(or $(CI_COMMIT_REF_NAME), $(BRANCH_NAME)))

#golang 基本信息
LDFLAGS += -s -w
LDFLAGS += -X "$(PROJECT_GO)/components/version.BuildTS=$(BUILD_TS)"
LDFLAGS += -X "$(PROJECT_GO)/components/version.GitHash=$(COMMIT_ID)"
LDFLAGS += -X "$(PROJECT_GO)/components/version.Version=$(VERSION)"
LDFLAGS += -X "$(PROJECT_GO)/components/version.GitBranch=$(CHANNEL)"
LDFLAGS += -linkmode external -extldflags -static

GCFLAGS = -c 4 -N -l
########### 通用环境变量 end #############

########### 必备命令 begin #############
.DEFAULT: all
.PHONY : all fmt lint test build clean

all: fmt lint test build clean

fmt:
	go list ./... | xargs -L1 go fmt

lint:
	go list ./... | xargs -L1 golint -set_exit_status

test: clean
	go test -tags skip -v ./... -coverprofile .coverage.txt
	go tool cover -func=.coverage.txt

build: clean
	go build -gcflags '$(GCFLAGS)' -ldflags '$(LDFLAGS)' -tags "libsqlite3 darwin amd64" -o $(PROJECT_NAME)

clean:
	-rm -fr $(PROJECT_NAME)*
	-rm -fr .coverage.txt
	-rm -fr cmd/$(PROJECT_NAME)/PROJECT_NAME
	-rm -fr build
########### 必备命令 end #############

########## 部署到机器上 ##############
GOPATH:=$(shell go env GOPATH)
dev_host=root@127.0.0.1

online:
	scp -r config/config.json $(dev_host):/data/apps/$(PROJECT_NAME)/config/config.json
	env CC=x86_64-linux-musl-gcc GOOS=linux CGO_ENABLED=1 go build -gcflags '$(GCFLAGS)' -ldflags '$(LDFLAGS)' -o $(PROJECT_NAME) && upx -1 $(PROJECT_NAME)
	ssh $(dev_host) -p 22 "mv /data/apps/$(PROJECT_NAME)/$(PROJECT_NAME) /data/apps/$(PROJECT_NAME)/$(PROJECT_NAME)-old"
	scp -r $(PROJECT_NAME) $(dev_host):/data/apps/$(PROJECT_NAME)/$(PROJECT_NAME)
	ssh $(dev_host) -p 22 "supervisorctl restart $(PROJECT_NAME)"

online_config_only:
	scp -r config/config.json $(dev_host):/data/apps/$(PROJECT_NAME)/config/config.json
	ssh $(dev_host) -p 22 "supervisorctl restart $(PROJECT_NAME)"

dev: PROJECT_NAME=go-template-dev
dev:
	scp -r config/config_dev.json $(dev_host):/data/apps/$(PROJECT_NAME)/config/config.json
	env CC=x86_64-linux-musl-gcc GOOS=linux CGO_ENABLED=1 go build -gcflags '$(GCFLAGS)' -ldflags '$(LDFLAGS)' -o $(PROJECT_NAME) && upx -1 $(PROJECT_NAME)
	ssh $(dev_host) -p 22 "mv /data/apps/$(PROJECT_NAME)/$(PROJECT_NAME) /data/apps/$(PROJECT_NAME)/$(PROJECT_NAME)-old"
	scp -r $(PROJECT_NAME) $(dev_host):/data/apps/$(PROJECT_NAME)/$(PROJECT_NAME)
	ssh $(dev_host) -p 22 "supervisorctl restart $(PROJECT_NAME)"

dev_config_only: PROJECT_NAME=go-template-dev
dev_config_only:
	scp -r config/config_dev.json $(dev_host):/data/apps/$(PROJECT_NAME)/config/config.json
	ssh $(dev_host) -p 22 "supervisorctl restart $(PROJECT_NAME)"
