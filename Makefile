.PHONY: help install build test lint clean anvil deploy-local keeper-local
.PHONY: build-evm build-svm test-evm test-svm

help:
	@echo "Sentinel Vault - Available Commands"
	@echo "======================================="
	@echo ""
	@echo "Setup:"
	@echo "  make install          Install all dependencies"
	@echo ""
	@echo "EVM Contracts (Solidity/Foundry):"
	@echo "  make build-evm        Build EVM contracts"
	@echo "  make test-evm         Run EVM contract tests"
	@echo "  make test-evm-v       Run EVM tests with verbosity"
	@echo "  make coverage-evm     Run EVM test coverage"
	@echo "  make gas-evm          Generate EVM gas report"
	@echo "  make fmt-evm          Format Solidity code"
	@echo "  make anvil            Start local Anvil node"
	@echo "  make deploy-local     Deploy to local Anvil"
	@echo ""
	@echo "SVM Contracts (Rust/Anchor) [Not Ready]:"
	@echo "  make build-svm        Build Solana program"
	@echo "  make test-svm         Run Anchor tests"
	@echo "  make deploy-svm-dev   Deploy to Solana devnet"
	@echo ""
	@echo "Keeper (Python):"
	@echo "  make keeper-install   Install Python dependencies"
	@echo "  make keeper-test      Run Python tests"
	@echo "  make keeper-local     Run keeper bot locally"
	@echo "  make keeper-lint      Lint Python code"
	@echo ""
	@echo "Utilities:"
	@echo "  make build            Build all contracts (EVM + SVM)"
	@echo "  make test             Run all tests"
	@echo "  make lint             Lint all code"
	@echo "  make clean            Clean build artifacts"

# =============================================================================
# Installation
# =============================================================================
install: install-evm keeper-install
	@echo "✅ All dependencies installed"

install-evm:
	@echo "📦 Installing EVM/Solidity dependencies..."
	cd contracts-evm && forge install

install-svm:
	@echo "🦀 Installing SVM/Anchor dependencies..."
	cd contracts-svm && anchor build 2>/dev/null || echo "⚠️  Anchor not installed. Run: cargo install --git https://github.com/coral-xyz/anchor avm --locked"

keeper-install:
	@echo "🐍 Installing Python dependencies..."
	cd keeper && uv sync

# =============================================================================
# EVM Build & Test (Foundry)
# =============================================================================
build-evm:
	@echo "🔨 Building EVM contracts..."
	cd contracts-evm && forge build

test-evm:
	@echo "🧪 Running EVM tests..."
	cd contracts-evm && forge test

test-evm-v:
	@echo "🧪 Running EVM tests (verbose)..."
	cd contracts-evm && forge test -vvv

coverage-evm:
	@echo "📊 Running EVM test coverage..."
	cd contracts-evm && forge coverage

gas-evm:
	@echo "⛽ Generating EVM gas report..."
	cd contracts-evm && forge test --gas-report

fmt-evm:
	@echo "✨ Formatting Solidity code..."
	cd contracts-evm && forge fmt

anvil:
	@echo "🔗 Starting local Anvil node..."
	anvil --block-time 2

deploy-local:
	@echo "🚀 Deploying to local Anvil..."
	cd contracts-evm && forge script script/Deploy.s.sol:DeployScript --rpc-url http://localhost:8545 --broadcast

# =============================================================================
# SVM Build & Test (Anchor) - Phase 4
# =============================================================================
build-svm:
	@echo "🦀 Building Solana program..."
	cd contracts-svm && anchor build

test-svm:
	@echo "🧪 Running Anchor tests..."
	cd contracts-svm && anchor test

deploy-svm-dev:
	@echo "🚀 Deploying to Solana devnet..."
	cd contracts-svm && anchor deploy --provider.cluster devnet

# =============================================================================
# Unified Commands (both chains)
# =============================================================================
build: build-evm
	@echo "✅ Build complete (EVM)"
	@echo "💡 Run 'make build-svm' for Solana (requires Anchor)"

test: test-evm keeper-test
	@echo "✅ All tests complete"

# Legacy aliases (backwards compatibility)
contracts-install: install-evm
fmt: fmt-evm
coverage: coverage-evm
gas: gas-evm

# =============================================================================
# Keeper (Python)
# =============================================================================
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

lint: fmt-evm keeper-lint
	@echo "✅ All linting complete"

clean:
	@echo "🧹 Cleaning build artifacts..."
	rm -rf contracts-evm/cache contracts-evm/out contracts-evm/broadcast
	rm -rf contracts-svm/target
	rm -rf keeper/.pytest_cache keeper/.ruff_cache keeper/.coverage
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@echo "✅ Clean complete"
