VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
BUILD_DATE ?= $(shell date -u '+%Y-%m-%d_%H:%M:%S')

WORKSPACE_ROOT := $(shell pwd)
SRC_DIR := $(WORKSPACE_ROOT)/src

help:
	@echo "Papyrxis Workspace"
	@echo ""
	@echo "Available targets:"
	@echo "  make help      - Show this help"
	@echo "  make sync      - Sync workspace components"
	@echo "  make build     - Build document"
	@echo "  make clean     - Clean build artifacts"
	@echo "  make watch     - Watch and rebuild on changes"
	@echo "  make version   - Show version information"

sync:
	@bash $(SRC_DIR)/sync.sh

build: sync
	@bash $(SRC_DIR)/build.sh

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf build/
	@find . -type f \( -name "*.aux" -o -name "*.log" -o -name "*.out" \
		-o -name "*.toc" -o -name "*.bbl" -o -name "*.blg" \
		-o -name "*.synctex.gz" -o -name "*.fdb_latexmk" -o -name "*.fls" \
		-o -name "*.idx" -o -name "*.ilg" -o -name "*.ind" \
		-o -name "*.run.xml" -o -name "*.bcf" \) -delete
	@echo "Clean complete!"

watch:
	@bash $(SRC_DIR)/build.sh -w

version:
	@echo "Version: $(VERSION)"
	@echo "Build date: $(BUILD_DATE)"

install:
	@echo "Installing scripts..."
	@sudo mkdir -p /usr/local/share/papyrxis
	@sudo cp -r $(SRC_DIR)/* /usr/local/share/papyrxis/
	@sudo cp -r common /usr/local/share/papyrxis/
	@sudo cp -r template /usr/local/share/papyrxis/
	@echo '#!/usr/bin/env bash' | sudo tee /usr/local/bin/papyrxis > /dev/null
	@echo 'exec bash /usr/local/share/papyrxis/init.sh "$$@"' | sudo tee -a /usr/local/bin/papyrxis > /dev/null
	@sudo chmod +x /usr/local/bin/papyrxis
	@echo "Papyrxis installed to /usr/local/bin/papyrxis"

.DEFAULT_GOAL := help