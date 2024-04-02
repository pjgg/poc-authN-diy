TARGET_DIR ?= bin
APP_NAME ?= osin-oidc-example
BIN_NAME ?= $(TARGET_DIR)/$(APP_NAME)
DOCKER_BIN_NAME ?= $(TARGET_DIR)/$(APP_NAME)-docker
PARENT_DIR := $(shell dirname $(PWD))
DEPLOYMENT ?= scripts

.PHONY: clean
clean:
	rm -rf $(TARGET_DIR)

.PHONY: dependencies
dependencies:
	go mod tidy -v

$(TARGET_DIR):
	mkdir -p $(TARGET_DIR)

# Compiles the binary if one of the .go files have been modified after the last build.
$(BIN_NAME): $(TARGET_DIR) $(shell find . -name "*.go")
	go build -ldflags "-w -s" -o $(BIN_NAME)

# Builds the binary in the host machine.
.PHONY: build
build: $(BIN_NAME)

# Run the binary in the host machine.
.PHONY: run
run: build ./$(BIN_NAME)

# Compiles the binary from a docker container.
$(DOCKER_BIN_NAME): $(TARGET_DIR) $(shell find . -name "*.go")
	docker run \
		-e GOOS=linux \
		-e GOARCH=amd64 \
		-e GOPATH=$(GOPATH) \
		-v $(GOPATH):$(GOPATH) \
		-v $(PARENT_DIR):/workspace/$(APP_NAME) \
		-w /workspace/$(APP_NAME) \
		--entrypoint /bin/sh \
		golang -c "go build -ldflags \"-w -s\" -o $(DOCKER_BIN_NAME)"

# Builds the binary in a docker container.
.PHONY: docker-build
docker-build: $(DOCKER_BIN_NAME)

# Launch the binary in a docker container.
.PHONY: docker-run
docker-run: docker-build
	docker run \
		-v $(PWD)/$(DOCKER_BIN_NAME):/api \
		-p 14000:14000 \
		-w / \
		--entrypoint /bin/sh \
		frolvlad/alpine-glibc \
		-c '/api'

.PHONY: unit-test
unit-test:
	go test -tags=unit ./...

.PHONY: build-docker-image
build-docker-image: 
	$(DEPLOYMENT)/build-image.sh

.PHONY: push-docker-image
push-docker-image: 
	$(DEPLOYMENT)/push-docker-image.sh