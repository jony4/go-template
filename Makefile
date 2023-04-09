########### 通用环境变量 begin #############
# 产品信息
PROJECT_GO = $(shell go list -m)
PROJECT_NAME = my_project_name
PRODUCT_NAME = NQ
VERSION = 1.4.0

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
GO111MODULE=off
CGO_ENABLED=1

#docker 信息
BUILD_IMAGE = registry.sensetime.com/nebula/golang-1.20.2_20230329
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
	-rm -fr nebula-bizapp-engine-service*
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


############### rv1126 conan ##############
conan: clean
	mkdir -p build/bin
	cp -fr storage/migrations ./build
	cd cmd/$(PROJECT_NAME) && \
	env GOARCH=arm64 CGO_ENABLED=1 CC=aarch64-linux-gnu-gcc GOOS=linux go build -gcflags "-N -l" -ldflags '$(LDFLAGS)' -o $(PROJECT_NAME) && upx -5 $(PROJECT_NAME) && \
	env GOARCH=arm CGO_ENABLED=1 CC=arm-linux-gnueabihf-gcc GOOS=linux go build -gcflags "-N -l" -ldflags '$(LDFLAGS)' -o $(PROJECT_NAME)-arm && upx -5 $(PROJECT_NAME)-arm
	cp cmd/$(PROJECT_NAME)/$(PROJECT_NAME) ./build/bin/$(PROJECT_NAME)
	conan user -p uayaeCh8 -r viper viper-robot
	conan export-pkg -f devops/conan/conanfile.py viper/$(CHANNEL) -s arch_target=armv8
	conan upload $(PROJECT_NAME)/$(CHANNEL)-$(COMMIT_ID)@viper/$(CHANNEL) -r viper --all --confirm
	rm -fr ./build/bin/$(PROJECT_NAME)
	cp cmd/$(PROJECT_NAME)/$(PROJECT_NAME)-arm ./build/bin/$(PROJECT_NAME)
	conan export-pkg -f devops/conan/conanfile.py viper/$(CHANNEL) -s arch_target=armv7hf
	conan upload $(PROJECT_NAME)/$(CHANNEL)-$(COMMIT_ID)@viper/$(CHANNEL) -r viper --all --confirm
############### rv1126 ##############

############## 开发部署到指定机器 begin ##########

build_dev_in_docker:
	docker rm -f gitlabci-bizapp-engine
	docker run --restart=always --privileged=true -it -v /root/go/src/gitlab.bj.sensetime.com/nebula/nebula-bizapp-engine-service:/go/src/gitlab.bj.sensetime.com/nebula/nebula-bizapp-engine-service --name gitlabci-bizapp-engine $(BUILD_IMAGE) /bin/sh -c 'cd src/gitlab.bj.sensetime.com/nebula/nebula-bizapp-engine-service; make dev'

build_dev_all_in_docker:
	docker rm -f gitlabci-bizapp-engine
	docker run --restart=always --privileged=true -it -v /root/go/src/gitlab.bj.sensetime.com/nebula/nebula-bizapp-engine-service:/go/src/gitlab.bj.sensetime.com/nebula/nebula-bizapp-engine-service --name gitlabci-bizapp-engine $(BUILD_IMAGE) /bin/sh -c 'cd src/gitlab.bj.sensetime.com/nebula/nebula-bizapp-engine-service; make dev_all'

dev=root@10.151.144.59
# ST#NBL#2018@all
dev_all: clean
	echo "ST#NBL#2018@all"
	cd devops/config && go run main.go && cd ../../
	cd cmd/$(PROJECT_NAME) && \
	env CGO_BUILD_OP=CGO_LDFLAGS="-fuse-ld=bfd" GO111MODULE=on CGO_ENABLED=1 GOARCH=arm CC=arm-linux-gnueabihf-gcc GOOS=linux go build -gcflags "-N -l" -ldflags '-s -w $(LDFLAGS)' -o $(PROJECT_NAME)-arm && \
	upx -5 $(PROJECT_NAME)-arm
	scp -r storage/migrations $(dev):/etc/nebula-bizapp-engine-service/migrations
	scp config/config.json $(dev):/etc/nebula-bizapp-engine-service/config.json
	scp devops/monit/nebula-bizapp-engine-service.monit $(dev):/etc/monit.d/nebula-bizapp-engine-service.monit
	scp cmd/$(PROJECT_NAME)/$(PROJECT_NAME)-arm $(dev):/usr/local/bin/nebula-bizapp-engine-service
dev: clean
	echo "ST#NBL#2018@all"
	cd cmd/$(PROJECT_NAME) && \
	env CGO_BUILD_OP=CGO_LDFLAGS="-fuse-ld=bfd" GO111MODULE=on CGO_ENABLED=1 GOARCH=arm CC=arm-linux-gnueabihf-gcc GOOS=linux go build -gcflags "-N -l" -ldflags '-s -w $(LDFLAGS)' -o $(PROJECT_NAME)-arm && \
	upx -5 $(PROJECT_NAME)-arm
	scp cmd/$(PROJECT_NAME)/$(PROJECT_NAME)-arm $(dev):/usr/local/bin/nebula-bizapp-engine-service

############# 测试 #################

build_test_in_docker:
	docker rm -f gitlabci-bizapp-engine
	docker run --restart=always --privileged=true -it -v /root/go/src/gitlab.bj.sensetime.com/nebula/nebula-bizapp-engine-service:/go/src/gitlab.bj.sensetime.com/nebula/nebula-bizapp-engine-service --name gitlabci-bizapp-engine $(BUILD_IMAGE) /bin/sh -c 'cd src/gitlab.bj.sensetime.com/nebula/nebula-bizapp-engine-service; make test_bin_only'

build_test_all_in_docker:
	docker rm -f gitlabci-bizapp-engine
	docker run --restart=always --privileged=true -it -v /root/go/src/gitlab.bj.sensetime.com/nebula/nebula-bizapp-engine-service:/go/src/gitlab.bj.sensetime.com/nebula/nebula-bizapp-engine-service --name gitlabci-bizapp-engine $(BUILD_IMAGE) /bin/sh -c 'cd src/gitlab.bj.sensetime.com/nebula/nebula-bizapp-engine-service; make test_all'

test=root@10.151.144.56
# ST#NBL#2018@all
test_all: clean
	echo "ST#NBL#2018@all"
	cd devops/config && go run main.go && cd ../../
	cd cmd/$(PROJECT_NAME) && \
	env CGO_BUILD_OP=CGO_LDFLAGS="-fuse-ld=bfd" GO111MODULE=on CGO_ENABLED=1 GOARCH=arm CC=arm-linux-gnueabihf-gcc GOOS=linux go build -gcflags "-N -l" -ldflags '-s -w $(LDFLAGS)' -o $(PROJECT_NAME)-arm && \
	upx -5 $(PROJECT_NAME)-arm
	scp -r storage/migrations $(test):/etc/nebula-bizapp-engine-service/migrations
	scp config/config.json $(test):/etc/nebula-bizapp-engine-service/config.json
	scp devops/monit/nebula-bizapp-engine-service.monit $(test):/etc/monit.d/nebula-bizapp-engine-service.monit
	scp cmd/$(PROJECT_NAME)/$(PROJECT_NAME)-arm $(test):/usr/local/bin/nebula-bizapp-engine-service
test_bin_only: clean
	echo "ST#NBL#2018@all"
	cd cmd/$(PROJECT_NAME) && \
	env CGO_BUILD_OP=CGO_LDFLAGS="-fuse-ld=bfd" GO111MODULE=on CGO_ENABLED=1 GOARCH=arm CC=arm-linux-gnueabihf-gcc GOOS=linux go build -gcflags "-N -l" -ldflags '-s -w $(LDFLAGS)' -o $(PROJECT_NAME)-arm && \
	upx -5 $(PROJECT_NAME)-arm
	scp cmd/$(PROJECT_NAME)/$(PROJECT_NAME)-arm $(test):/usr/local/bin/nebula-bizapp-engine-service

############## 开发部署到指定机器 end ##########
