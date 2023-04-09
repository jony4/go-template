########### 通用环境变量 begin #############
# 产品信息
PROJECT_GO = $(shell go list -m)
PROJECT_NAME = my_project_name
PRODUCT_NAME = NQ
VERSION = 1.0.0

# git 仓库基本信息
BRANCH_NAME = $(shell git rev-parse --abbrev-ref HEAD)
BUILD_TS = $(shell TZ=UTC-8 date +"%Y-%m-%d %H:%M:%S")
COMMIT_ID = $(shell git rev-parse --short=8 HEAD)
CHANNEL := $(subst /,-,$(or $(CI_COMMIT_REF_NAME), $(BRANCH_NAME)))

#golang 基本信息
LDFLAGS += -X "$(PROJECT_GO)/version.BuildTS=$(BUILD_TS)"
LDFLAGS += -X "$(PROJECT_GO)/version.GitHash=$(COMMIT_ID)"
LDFLAGS += -X "$(PROJECT_GO)/version.Version=$(VERSION)"
LDFLAGS += -X "$(PROJECT_GO)/version.GitBranch=$(CHANNEL)"
CGO_ENABLED=1
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
	cd cmd/$(PROJECT_NAME) && \
	go build -ldflags '$(LDFLAGS)' -trimpath -o $(PROJECT_NAME)

clean:
	-rm -fr $(PROJECT_NAME)*
	-rm -fr .coverage.txt
	-rm -fr cmd/$(PROJECT_NAME)/PROJECT_NAME
	-rm -fr build
########### 必备命令 end #############

########## 部署到机器上 ##############
GOPATH:=$(shell go env GOPATH)
dev=root@175.24.233.40

online:
	@rsync -e 'ssh -p 22' -c config/config.json $(dev):/data/apps/$(PROJECT_NAME)/$(PROJECT_NAME).json
	scp -r storage/migrations $(dev):/data/apps/$(PROJECT_NAME)/migrations
	env GOOS=linux go build -v -gcflags "-N -l" -ldflags '$(LDFLAGS)' -ldflags "-s -w" -o $(PROJECT_NAME) && upx -1 $(PROJECT_NAME)
	ssh $(dev) -p 22 "mv /data/apps/$(PROJECT_NAME)/$(PROJECT_NAME) /data/apps/$(PROJECT_NAME)/$(PROJECT_NAME)-old"
	@rsync -e 'ssh -p 22' -c $(PROJECT_NAME) $(dev):/data/apps/$(PROJECT_NAME)/$(PROJECT_NAME)
	ssh $(dev) -p 22 "supervisorctl restart $(PROJECT_NAME)"
########## 部署到机器上 ##############

