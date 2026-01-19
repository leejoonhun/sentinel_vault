# Contributing to Sentinel Protocol

First off, thank you for considering contributing to Sentinel Protocol! 🎉

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Pull Request Process](#pull-request-process)
- [Style Guides](#style-guides)

---

## Code of Conduct

This project and everyone participating in it is governed by our commitment to providing a welcoming and inclusive environment. Please be respectful and constructive in all interactions.

---

## Getting Started

### Types of Contributions

We welcome many types of contributions:

- 🐛 **Bug Reports** - Found a bug? Open an issue!
- 💡 **Feature Requests** - Have an idea? We'd love to hear it!
- 📖 **Documentation** - Help improve our docs
- 🔧 **Code** - Fix bugs or implement new features
- 🧪 **Tests** - Help improve our test coverage

### Finding Issues to Work On

- Look for issues labeled `good first issue` for beginner-friendly tasks
- Issues labeled `help wanted` are actively seeking contributors
- Feel free to ask questions on any issue before starting work

---

## Development Setup

### Prerequisites

- [Foundry](https://getfoundry.sh/) - Solidity development
- [Python 3.11+](https://www.python.org/)
- [uv](https://docs.astral.sh/uv/) - Python package manager
- [Git](https://git-scm.com/)

### Setup Steps

```bash
# 1. Fork the repository on GitHub

# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/sentinel_vault.git
cd sentinel_vault

# 3. Add upstream remote
git remote add upstream https://github.com/original/sentinel_vault.git

# 4. Install dependencies
make install

# 5. Install pre-commit hooks
pip install pre-commit
pre-commit install

# 6. Create a branch for your changes
git checkout -b feature/your-feature-name
```

---

## Making Changes

### Contracts (Solidity)

```bash
# Navigate to contracts
cd contracts

# Make your changes, then:

# Format code
forge fmt

# Run tests
forge test

# Check coverage
forge coverage
```

### Keeper (Python)

```bash
# Navigate to keeper
cd keeper

# Make your changes, then:

# Format code
uv run ruff format .

# Lint code
uv run ruff check .

# Type check
uv run mypy sentinel_keeper

# Run tests
uv run pytest
```

---

## Pull Request Process

### Before Submitting

1. ✅ All tests pass (`make test`)
2. ✅ Code is formatted (`make fmt`)
3. ✅ No linting errors (`make lint`)
4. ✅ New code has tests
5. ✅ Documentation is updated (if needed)

### Submitting

1. Push your branch to your fork
2. Open a Pull Request against `main`
3. Fill out the PR template completely
4. Link any related issues

### PR Title Convention

Use conventional commits format:

- `feat: add new feature`
- `fix: resolve bug in X`
- `docs: update README`
- `test: add tests for Y`
- `refactor: improve Z`
- `chore: update dependencies`

### Review Process

1. A maintainer will review your PR
2. Address any requested changes
3. Once approved, a maintainer will merge

---

## Style Guides

### Solidity

- Follow [Solidity Style Guide](https://docs.soliditylang.org/en/latest/style-guide.html)
- Use `forge fmt` for formatting
- Maximum line length: 100 characters
- Use NatSpec comments for all public functions

```solidity
/// @notice Deposits tokens into the vault
/// @param token The token address to deposit
/// @param amount The amount to deposit
/// @return success Whether the deposit succeeded
function deposit(address token, uint256 amount) external returns (bool success) {
    // Implementation
}
```

### Python

- Follow [PEP 8](https://peps.python.org/pep-0008/)
- Use `ruff` for linting and formatting
- Maximum line length: 88 characters
- Use type hints for all functions

```python
def process_order(order_id: int, params: OrderParams) -> ExecutionResult:
    """Process an order for execution.

    Args:
        order_id: The unique order identifier.
        params: The order parameters.

    Returns:
        The execution result.
    """
    # Implementation
```

### Commit Messages

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit first line to 72 characters
- Reference issues and PRs in the body

---

## Questions?

Feel free to:

- Open a [Discussion](https://github.com/your-username/sentinel_vault/discussions)
- Ask in the issue you're working on
- Reach out on Discord

Thank you for contributing! 🙏
