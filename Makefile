VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
BUILD_DATE ?= $(shell date -u '+%Y-%m-%d_%H:%M:%S')

WORKSPACE_ROOT := $(shell pwd)
SRC_DIR := $(WORKSPACE_ROOT)/src
WORKSPACE := workspace

ifeq ($(shell [ -d "$(WORKSPACE)" ] && echo 1 || echo 0), 1)
    WORKSPACE_SRC := $(WORKSPACE)/src
else
    WORKSPACE_SRC := $(SRC_DIR)
endif

all: sync build

sync:
	@bash $(WORKSPACE_SRC)/sync.sh

build: sync
	@bash $(WORKSPACE_SRC)/build.sh

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf build/
	@find . -type f \( \
		-name "*.aux" -o -name "*.log" -o -name "*.out" \
		-o -name "*.toc" -o -name "*.bbl" -o -name "*.blg" \
		-o -name "*.synctex.gz" -o -name "*.fdb_latexmk" \
		-o -name "*.fls" -o -name "*.idx" -o -name "*.ilg" \
		-o -name "*.ind" -o -name "*.run.xml" -o -name "*.bcf" \
		\) -delete 2>/dev/null || true
	@echo "✓ Clean complete"

watch:
	@bash $(WORKSPACE_SRC)/build.sh -w

version:
	@echo "Version: $(VERSION)"
	@echo "Build date: $(BUILD_DATE)"

part:
	@bash $(WORKSPACE_SRC)/generator/part.sh $(ARGS)

chapter:
	@bash $(WORKSPACE_SRC)/generator/chapter.sh $(ARGS)

cover:
	@bash $(WORKSPACE_SRC)/generator/cover.sh workspace.yml

test:
	@echo "Building document..."
	@$(MAKE) clean >/dev/null 2>&1
	@$(MAKE) build >/dev/null 2>&1 && echo "✓ Build successful" || echo "✗ Build failed"

help:
	@echo "Papyrxis Workspace - Build System"
	@echo ""
	@echo "MAIN TARGETS:"
	@echo "  make            Build document (sync + build)"
	@echo "  make sync       Sync workspace components from workspace.yml"
	@echo "  make build      Build LaTeX document"
	@echo "  make clean      Remove all build artifacts"
	@echo "  make watch      Watch mode (auto-rebuild on changes)"
	@echo ""
	@echo "GENERATORS:"
	@echo "  make part ARGS='-n 2 -t \"Part Title\"'"
	@echo "  make chapter ARGS='-p 1 -c 2 -t \"Chapter Title\"'"
	@echo "  make cover      Generate cover page"
	@echo ""
	@echo "UTILITIES:"
	@echo "  make version    Show version information"
	@echo "  make test       Quick build test"
	@echo "  make help       Show this help"
	@echo ""
	@echo "EXAMPLES:"
	@echo "  make                                    # Build document"
	@echo "  make watch                              # Auto-rebuild"
	@echo "  make part ARGS='-n 1 -t \"Introduction\"'"
	@echo "  make chapter ARGS='-p 1 -c 1 -t \"Getting Started\"'"
	@echo ""
	@echo "For more information: docs/getting-started.md"

.DEFAULT_GOAL := all