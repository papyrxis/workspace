VERSION    ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
BUILD_DATE ?= $(shell date -u '+%Y-%m-%d_%H:%M:%S')

WORKSPACE_ROOT := $(shell pwd)
SRC_DIR        := $(WORKSPACE_ROOT)/src

ifeq ($(shell [ -d "workspace" ] && echo 1 || echo 0), 1)
    WORKSPACE_SRC := workspace/src
else
    WORKSPACE_SRC := $(SRC_DIR)
endif

.PHONY: all build sync clean watch version part chapter help

all: build

sync:
	@bash $(WORKSPACE_SRC)/sync.sh

build:
	@bash $(WORKSPACE_SRC)/build.sh

watch:
	@bash $(WORKSPACE_SRC)/build.sh -w

clean:
	@echo "Cleaning..."
	@rm -rf build/
	@find . -type f \( \
		-name "*.aux" -o -name "*.log" -o -name "*.out" \
		-o -name "*.toc" -o -name "*.bbl" -o -name "*.blg" \
		-o -name "*.synctex.gz" -o -name "*.fdb_latexmk" \
		-o -name "*.fls" -o -name "*.idx" -o -name "*.ilg" \
		-o -name "*.ind" -o -name "*.run.xml" -o -name "*.bcf" \
		\) -delete 2>/dev/null || true
	@echo "✓ Clean"

part:
	@bash $(WORKSPACE_SRC)/generator/part.sh $(ARGS)

chapter:
	@bash $(WORKSPACE_SRC)/generator/chapter.sh $(ARGS)

version:
	@echo "Version:    $(VERSION)"
	@echo "Build date: $(BUILD_DATE)"

help:
	@echo ""
	@echo "  Papyrxis Workspace"
	@echo "  ──────────────────────────────────────"
	@echo ""
	@echo "  make              Build document"
	@echo "  make sync         Sync .pxis/ from workspace.yml"
	@echo "  make watch        Auto-rebuild on save"
	@echo "  make clean        Remove build artifacts"
	@echo ""
	@echo "  make part    ARGS='-n 2 -t \"Part Title\"'"
	@echo "  make chapter ARGS='-p 1 -c 2 -t \"Chapter Title\"'"
	@echo ""
	@echo "  make version      Show version info"
	@echo "  make help         This message"
	@echo ""

.DEFAULT_GOAL := all
