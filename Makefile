# Variables
PROJECT_DIR := $(shell pwd)
DOCKER_IMAGE := openevolve
# Try to read API keys from .env file, fall back to environment variables
OPENAI_API_KEY := $(shell if [ -f .env ]; then cat .env | grep OPENAI_API_KEY | cut -d '=' -f 2; else echo $$OPENAI_API_KEY; fi)
OPENROUTER_API_KEY := $(shell if [ -f .env ]; then cat .env | grep OPENROUTER_API_KEY | cut -d '=' -f 2; else echo $$OPENROUTER_API_KEY; fi)

# Default target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  all            - Install dependencies and run tests"
	@echo "  check-uv       - Check if uv is installed, install if not"
	@echo "  sync           - Sync dependencies using uv"
	@echo "  install        - Install project in development mode"
	@echo "  lint           - Run Black code formatting"
	@echo "  test           - Run tests"
	@echo "  docker-build   - Build the Docker image"
	@echo "  docker-run     - Run the Docker container with the example"
	@echo "  visualizer     - Run the visualization script"

.PHONY: all
all: install test

# Check if uv is installed, install if not
.PHONY: check-uv
check-uv:
	@command -v uv >/dev/null 2>&1 || { \
		echo "uv not found, installing..."; \
		curl -LsSf https://astral.sh/uv/install.sh | sh; \
		echo "uv installed successfully. You may need to restart your shell or run 'source ~/.bashrc' (or ~/.zshrc)"; \
	}

# Sync dependencies using uv
.PHONY: sync
sync: check-uv
	uv sync

# Install project in development mode
.PHONY: install
install: check-uv
	uv sync
	uv pip install -e .

# Run Black code formatting
.PHONY: lint
lint: check-uv
	uv run black openevolve examples tests scripts

# Run tests using uv
.PHONY: test
test: check-uv
	uv run python -m unittest discover -s tests -p "test_*.py"

# Build the Docker image
.PHONY: docker-build
docker-build:
	docker build -t $(DOCKER_IMAGE) .

# Run the Docker container with the example
.PHONY: docker-run
docker-run:
	docker run --rm -v $(PROJECT_DIR):/app --network="host" $(DOCKER_IMAGE) examples/function_minimization/initial_program.py examples/function_minimization/evaluator.py --config examples/function_minimization/config.yaml --iterations 2

# Run the visualization script
.PHONY: visualizer
visualizer: check-uv
	uv run python scripts/visualizer.py --path examples/

test-example: check-uv
	@echo "Installing example-specific dependencies..."
	uv pip install -r examples/mlx_metal_kernel_opt/requirements.txt
	@echo "Running MLX Metal Kernel Optimization example with OpenAI models..."
	uv run python openevolve-run.py examples/mlx_metal_kernel_opt/initial_program.py examples/mlx_metal_kernel_opt/evaluator.py --config examples/mlx_metal_kernel_opt/config.yaml --iterations 100
