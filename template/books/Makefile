# Makefile for LaTeX projects

VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
BUILD_DATE ?= $(shell date -u '+%Y-%m-%d_%H:%M:%S')

MAIN = main
ENGINE = pdflatex
BIBTEX = biber
BUILD_DIR = build
SCRIPTS_DIR = ../../scripts

LATEX_FLAGS = -output-directory=$(BUILD_DIR) -interaction=nonstopmode
WATCH_EXCLUDE = --exclude '\.git|$(BUILD_DIR)/'

.PHONY: all build clean watch help version

all: build

build: $(BUILD_DIR)/$(MAIN).pdf

$(BUILD_DIR)/$(MAIN).pdf: $(MAIN).tex
	@echo "Building $(MAIN).pdf..."
	@mkdir -p $(BUILD_DIR)
	@export VERSION=$(VERSION) BUILD_DATE=$(BUILD_DATE) && \
	$(ENGINE) $(LATEX_FLAGS) $(MAIN).tex || true
	@if grep -q '\\bibliography\|\\addbibresource' $(MAIN).tex; then \
		echo "Running $(BIBTEX)..."; \
		(cd $(BUILD_DIR) && $(BIBTEX) $(MAIN)) || true; \
	fi
	@$(ENGINE) $(LATEX_FLAGS) $(MAIN).tex || true
	@$(ENGINE) $(LATEX_FLAGS) $(MAIN).tex
	@echo "Success! Output: $(BUILD_DIR)/$(MAIN).pdf"
	@echo "Version: $(VERSION)"
	@echo "Build date: $(BUILD_DATE)"

clean:
	@echo "Cleaning build directory..."
	@rm -rf $(BUILD_DIR)

watch:
	@echo "Entering watch mode..."
	@while true; do \
		$(MAKE) build; \
		echo "Waiting for changes..."; \
		inotifywait -e modify -r . $(WATCH_EXCLUDE) 2>/dev/null || sleep 2; \
	done

version:
	@echo "Version: $(VERSION)"
	@echo "Build date: $(BUILD_DATE)"

help:
	@echo "Available targets:"
	@echo "  make          - Build the document"
	@echo "  make build    - Build the document"
	@echo "  make clean    - Remove build artifacts"
	@echo "  make watch    - Watch for changes and rebuild"
	@echo "  make version  - Show version information"
	@echo "  make help     - Show this help"
	@echo ""
	@echo "Environment variables:"
	@echo "  VERSION       - Override version (default: git describe)"
	@echo "  BUILD_DATE    - Override build date (default: current date)"
	@echo "  ENGINE        - LaTeX engine (default: pdflatex)"
	@echo "  BIBTEX        - Bibliography tool (default: biber)"