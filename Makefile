PROJ=dex
ORG_PATH=github.com/coreos
REPO_PATH=$(ORG_PATH)/$(PROJ)
export PATH := $(PWD)/bin:$(PATH)

TAG ?="latest"
VERSION ?= $(shell ./scripts/git-version)

DOCKER_REPO=569325332953.dkr.ecr.us-east-1.amazonaws.com/dex
DOCKER_REPO_EXAMPLE_APP=569325332953.dkr.ecr.us-east-1.amazonaws.com/dex-signin
DOCKER_IMAGE=$(DOCKER_REPO):$(VERSION)
DOCKER_IMAGE_EXAMPLE_APP=$(DOCKER_REPO_EXAMPLE_APP):$(VERSION)

$( shell mkdir -p bin )

user=$(shell id -u -n)
group=$(shell id -g -n)

export GOBIN=$(PWD)/bin

LD_FLAGS="-w -X $(REPO_PATH)/version.Version=$(VERSION)"

build: bin/dex bin/example-app bin/grpc-client

bin/dex: check-go-version
	@go install -v -ldflags $(LD_FLAGS) $(REPO_PATH)/cmd/dex

bin/example-app: check-go-version
	@mkdir -p static/
	@cp -r cmd/example-app/static/ static/
	@go install -v -ldflags $(LD_FLAGS) $(REPO_PATH)/cmd/example-app

bin/grpc-client: check-go-version
	@go install -v -ldflags $(LD_FLAGS) $(REPO_PATH)/examples/grpc-client

.PHONY: release-binary
release-binary:
	@go build -o /go/bin/dex -v -ldflags $(LD_FLAGS) $(REPO_PATH)/cmd/dex

.PHONY: release-binary-example-app
release-binary-example-app:
	@go build -o /go/bin/example-app -v -ldflags $(LD_FLAGS) $(REPO_PATH)/cmd/example-app

.PHONY: revendor
revendor:
	@glide up -v
	@glide-vc --use-lock-file --no-tests --only-code

test:
	@go test -v -i $(shell go list ./... | grep -v '/vendor/')
	@go test -v $(shell go list ./... | grep -v '/vendor/')

testrace:
	@go test -v -i --race $(shell go list ./... | grep -v '/vendor/')
	@go test -v --race $(shell go list ./... | grep -v '/vendor/')

vet:
	@go vet $(shell go list ./... | grep -v '/vendor/')

fmt:
	@./scripts/gofmt $(shell go list ./... | grep -v '/vendor/')

lint:
	@for package in $(shell go list ./... | grep -v '/vendor/' | grep -v '/api' | grep -v '/server/internal'); do \
      golint -set_exit_status $$package $$i || exit 1; \
	done

.PHONY: docker-image
docker-image:
	@sudo docker build -t $(DOCKER_IMAGE) .
	@sudo docker tag $(DOCKER_IMAGE) $(DOCKER_REPO):$(TAG)

.PHONY: docker-image-example-app
docker-image-example-app: generate-example-app-output
	@sudo docker build -f Dockerfile-example-app -t $(DOCKER_IMAGE_EXAMPLE_APP) .
	@sudo docker tag $(DOCKER_IMAGE_EXAMPLE_APP) $(DOCKER_REPO_EXAMPLE_APP):$(TAG)

.PHONY: generate-example-app-output
generate-example-app-output:
	rm -rf _output/bin
	rm -rf _output/**/*.css
	mkdir -p _output/bin
	cp bin/example-app _output/bin/
	cp -r static _output/

.PHONY: proto
proto: bin/protoc bin/protoc-gen-go
	@./bin/protoc --go_out=plugins=grpc:. --plugin=protoc-gen-go=./bin/protoc-gen-go api/*.proto
	@./bin/protoc --go_out=. --plugin=protoc-gen-go=./bin/protoc-gen-go server/internal/*.proto

.PHONY: verify-proto
verify-proto: proto
	@./scripts/git-diff

bin/protoc: scripts/get-protoc
	@./scripts/get-protoc bin/protoc

bin/protoc-gen-go:
	@go install -v $(REPO_PATH)/vendor/github.com/golang/protobuf/protoc-gen-go

.PHONY: check-go-version
check-go-version:
	@./scripts/check-go-version

clean:
	@rm -rf bin/

testall: testrace vet fmt lint

FORCE:

.PHONY: test testrace vet fmt lint testall
