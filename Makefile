.PHONY: help install build test lint clean anvil deploy-local keeper-local

help:
	@echo "Sentinel Vault - Available Commands"
	@echo "======================================="
	@echo ""
	@echo "Setup:"
	@echo "  make install        Install all dependencies (contracts + keeper)"
	@echo ""
	@echo "Contracts:"
	@echo "  make build          Build Solidity contracts"
	@echo "  make test           Run Forge tests"
	@echo "  make test-v         Run Forge tests with verbosity"
	@echo "  make coverage       Run test coverage"
	@echo "  make gas            Generate gas report"
	@echo "  make fmt            Format Solidity code"
	@echo "  make anvil          Start local Anvil node"
	@echo "  make deploy-local   Deploy contracts to local Anvil"
	@echo ""
	@echo "Keeper:"
	@echo "  make keeper-install Install Python dependencies"
	@echo "  make keeper-test    Run Python tests"
	@echo "  make keeper-local   Run keeper bot locally"
	@echo "  make keeper-lint    Lint Python code"
	@echo ""
	@echo "Utilities:"
	@echo "  make lint           Lint all code (Solidity + Python)"
	@echo "  make clean          Clean build artifacts"

install: contracts-install keeper-install
	@echo "✅ All dependencies installed"

contracts-install:
	@echo "📦 Installing Solidity dependencies..."
	cd contracts && forge install

keeper-install:
	@echo "🐍 Installing Python dependencies..."
	cd keeper && uv sync

build:
	@echo "🔨 Building contracts..."
	cd contracts && forge build

test:
	@echo "🧪 Running Forge tests..."
	cd contracts && forge test

test-v:
	@echo "🧪 Running Forge tests (verbose)..."
	cd contracts && forge test -vvv

coverage:
	@echo "📊 Running test coverage..."
	cd contracts && forge coverage

gas:
	@echo "⛽ Generating gas report..."
	cd contracts && forge test --gas-report

fmt:
	@echo "✨ Formatting Solidity code..."
	cd contracts && forge fmt

anvil:
	@echo "🔗 Starting local Anvil node..."
	anvil --block-time 2

deploy-local:
	@echo "🚀 Deploying to local Anvil..."
	cd contracts && forge script script/Deploy.s.sol:DeployScript --rpc-url http://localhost:8545 --broadcast

keeper-test:
	@echo "🧪 Running Python tests..."
	cd keeper && uv run pytest

keeper-test-cov:
	@echo "📊 Running Python tests with coverage..."
	cd keeper && uv run pytest --cov=sentinel_keeper --cov-report=html

keeper-local:
	@echo "🤖 Starting keeper bot..."
	cd keeper && uv run python -m sentinel_keeper.main

keeper-lint:
	@echo "🔍 Linting Python code..."
	cd keeper && uv run ruff check .
	cd keeper && uv run ruff format --check .

keeper-fmt:
	@echo "✨ Formatting Python code..."
	cd keeper && uv run ruff format .

lint: fmt keeper-lint
	@echo "✅ All linting complete"

clean:
	@echo "🧹 Cleaning build artifacts..."
	rm -rf contracts/cache contracts/out contracts/broadcast
	rm -rf keeper/.pytest_cache keeper/.ruff_cache keeper/.coverage
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@echo "✅ Clean complete"
