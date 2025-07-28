M := $(or $(MAKES_REPO_DIR),.cache/makes)
C := ca8c2c25e66cf6bfcf8c993502de5b98da5beaf5
$(shell [ -d $M ] || ( \
    git clone --depth=1 -q https://github.com/makeplus/makes $M && \
    git -C $M reset -q --hard $C))
include $M/init.mk
include $M/clojure.mk
DOCKER-FILES := compiler+runtime/build.dockerfile
include $M/docker.mk
include $M/clean.mk
include $M/shell.mk

WORK      := $(ROOT)/compiler+runtime
JANK-3RD  := $(WORK)/third-party/cpptrace/LICENSE
JANK-DEPS := $(JANK-3RD)
JANK-BLD  := $(WORK)/build
JANK      := $(JANK-BLD)/jank
JANK-RUN  := $(LOCAL-BIN)/jank

MAKES-CLEAN := \
  $(LOCAL-LIB)/libclang-cpp.so.19.1 \
  $(JANK-BLD) \
  $(JANK-RUN) \
  $(ROOT)/.jank-repl-history \

override PATH := $(LOCAL-BIN):$(JANK-BLD):$(PATH)

ifndef LC_ALL
export LC_ALL := C.UTF-8
endif

ifndef LLVM_DIR
ifneq (,$(wildcard /usr/lib/llvm-19))
export LLVM_DIR := /usr/lib/llvm-19
endif
endif

repl: build
	jank $@

ifndef IN-DOCKER
build: $(JANK-3RD) $(JANK-RUN)

$(JANK-3RD):
	git submodule update --init --recursive

$(JANK): $(DOCKER-BUILD-FILE)
	docker run -it --rm \
	  --workdir $(ROOT) \
	  --volume $(GIT-REPO-DIR):$(GIT-REPO-DIR) \
	  --env HOST_UID=$(USER-UID) \
	  --env HOST_GID=$(USER-GID) \
	  $(DOCKER-NAME) \
	  make build

$(JANK-RUN): $(JANK)
	@( \
	  echo '#!/usr/bin/env bash'; \
	  echo 'export LD_LIBRARY_PATH="$(LOCAL-LIB)"'; \
	  echo 'exec $(JANK) "$$@"'; \
	) > $@
	chmod +x $@

else
build: $(JANK)
	touch $<

$(JANK): $(JANK-DEPS)
ifndef LLVM_DIR
	@echo 'export LLVM_DIR=<llvm-path>'
	@exit 1
endif
	@( \
	  set -x && \
	  cd $(WORK) && \
	  ./bin/configure -GNinja -DCMAKE_BUILD_TYPE=Release && \
	  time ./bin/compile \
	)
	cp /usr/lib/llvm-19/lib/libclang-cpp.so.19.1 $(LOCAL-LIB)/
	chown -R $$HOST_UID:$$HOST_GID $(ROOT)
endif
