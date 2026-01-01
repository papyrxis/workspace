help:
	@echo "Papyrxis Workspace"
	@echo ""
	@echo "Available targets:"
	@echo "  make help      - Show this help"
	@echo "  make test      - Run tests"
	@echo "  make examples  - Build example projects"
	@echo "  make docs      - Build documentation"
	@echo "  make clean     - Clean all build artifacts"
	@echo "  make install   - Install scripts system-wide"
	@echo ""
	@echo "Project creation:"
	@echo "  ./scripts/new-project.sh -t book -n my-book"
	@echo "  ./scripts/new-project.sh -t article -n my-paper"

test:
	@echo "Running tests..."
	@bash tests/run-tests.sh

examples:
	@echo "Building examples..."
	@for ex in examples/*/; do \
		echo "Building $$ex..."; \
		(cd "$$ex" && make) || exit 1; \
	done

docs:
	@echo "Building documentation..."
	@(cd docs && make html)

clean:
	@echo "Cleaning build artifacts..."
	@find . -type d -name "build" -exec rm -rf {} + 2>/dev/null || true
	@find . -name "*.aux" -o -name "*.log" -o -name "*.out" | xargs rm -f

install:
	@echo "Installing scripts..."
	@sudo cp scripts/*.sh /usr/local/bin/
	@sudo chmod +x /usr/local/bin/*.sh
	@echo "Scripts installed to /usr/local/bin/"

.DEFAULT_GOAL := help