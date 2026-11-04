PYTHON ?= python3
PX ?= $(PYTHON) -m px
TYPE ?= book
LANGUAGE ?=
TARGET ?= devto
LEVEL ?= patch
VERSION ?=
TAGS ?= 0

.PHONY: all help init build build-en build-fa build-all watch clean export tags changelog bump tag push doctor test sync part chapter

all: help

init:
	@$(PX) init --type "$(TYPE)"

build:
	@$(PX) build $(if $(LANGUAGE),--language "$(LANGUAGE)",)

build-en:
	@$(PX) build --language en

build-fa:
	@$(PX) build --language fa

build-all:
	@$(PX) build

watch:
	@$(PX) watch

clean:
	@$(PX) clean

export:
	@$(PX) export --target "$(TARGET)"

tags:
	@$(PX) tags

changelog:
	@$(PX) changelog

bump:
	@gix version bump "$(LEVEL)"

tag:
ifndef VERSION
	$(error VERSION is required. Usage: make tag VERSION=v1.2.0)
endif
	@$(PX) tag "$(VERSION)" --sign

push:
	@$(PX) push $(if $(filter 1,$(TAGS)),--tags,)

doctor:
	@$(PX) doctor

test:
	@$(PYTHON) -m unittest discover -s tests -p "test_*.py" -v

sync:
	@bash src/sync.sh

part:
	@bash src/generator/part.sh $(ARGS)

chapter:
	@bash src/generator/chapter.sh $(ARGS)

version:
	@gix version current

help:
	@echo "Papyrxis Workspace"
	@echo "  make init TYPE=book"
	@echo "  make build | build-en | build-fa | build-all"
	@echo "  make export TARGET=devto"
	@echo "  make tags | changelog | bump LEVEL=minor"
	@echo "  make tag VERSION=v1.2.0 | push TAGS=1"
	@echo "  make clean | doctor | test"
	@echo "  make sync | part ARGS='...' | chapter ARGS='...' (legacy generators)"

.DEFAULT_GOAL := all
