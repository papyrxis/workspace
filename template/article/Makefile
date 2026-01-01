VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
BUILD_DATE ?= $(shell date -u '+%Y-%m-%d_%H:%M:%S')

MAIN = main
ENGINE = pdflatex
BIBTEX = biber
BUILD_DIR = build

.PHONY: all build clean watch version help

all: build

build: $(BUILD_DIR)/$(MAIN).pdf

$(BUILD_DIR)/$(MAIN).pdf: $(MAIN).tex
	@echo "Building $(MAIN).pdf..."
	@mkdir -p $(BUILD_DIR)
	@export VERSION=$(VERSION) BUILD_DATE=$(BUILD_DATE) && \
	$(ENGINE) -output-directory=$(BUILD_DIR) $(MAIN).tex || true
	@if grep -q '\\bibliography\|\\addbibresource' $(MAIN).tex; then \
		(cd $(BUILD_DIR) && $(BIBTEX) $(MAIN)) || true; \
	fi
	@$(ENGINE) -output-directory=$(BUILD_DIR) $(MAIN).tex || true
	@$(ENGINE) -output-directory=$(BUILD_DIR) $(MAIN).tex
	@echo "Success: $(BUILD_DIR)/$(MAIN).pdf"

clean:
	@rm -rf $(BUILD_DIR)

watch:
	@while true; do \
		$(MAKE) build; \
		inotifywait -e modify -r . --exclude '\.git|$(BUILD_DIR)/' 2>/dev/null || sleep 2; \
	done

version:
	@echo "Version: $(VERSION)"
	@echo "Build date: $(BUILD_DATE)"

help:
	@echo "Available targets:"
	@echo "  make        - Build article"
	@echo "  make clean  - Remove build artifacts"
	@echo "  make watch  - Watch and rebuild on changes"
	@echo "  make version - Show version info"