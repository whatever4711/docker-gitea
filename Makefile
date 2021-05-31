PLATFORMS = linux/amd64,linux/i386,linux/arm64,linux/arm/v7,linux/arm/v6
VERSION = $(shell cat VERSION)
builder = xbuilder

comma := ,

ifeq ($(REPO),)
  REPO = gitea
endif
ifeq ($(CIRCLE_TAG),)
	TAG = latest
else
	TAG = $(CIRCLE_TAG)
endif

.PHONY: all init build build_local clean

all: init build_local clean

init: clean
	@docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	@docker context create $(builder)
	@docker buildx create --name $(builder) --name $(builder) --driver docker-container --use
	@docker buildx inspect --bootstrap

build:
	@docker login -u $(DOCKER_USER) -p $(DOCKER_PASS)
	@docker buildx build \
			--build-arg BUILD_DATE=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ") \
			--build-arg VCS_REF=$(shell git rev-parse --short HEAD) \
			--build-arg VCS_URL=$(shell git config --get remote.origin.url) \
			--build-arg VERSION=$(VERSION) \
			--progress plain \
			--platform $(PLATFORMS) \
			--push \
			-t $(REPO):$(TAG) .
	@docker logout

clean:
	@docker buildx rm $(builder) | true
	@docker context rm $(builder) | true

# To test the "buildx" locally
build_local: init
	@docker buildx build \
			--build-arg BUILD_DATE=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ") \
			--build-arg VCS_REF=$(shell git rev-parse --short HEAD) \
			--build-arg VCS_URL=$(shell git config --get remote.origin.url) \
			--build-arg VERSION=$(VERSION) \
			--platform $(firstword $(subst $(comma), ,$(PLATFORMS))) \
			--load \
			-t $(REPO):$(TAG) .
