"""Chain module.

Handles blockchain connectivity, event indexing, and transaction management.

This module provides a unified interface for interacting with multiple blockchains:
- EVM-compatible chains (Ethereum, Arbitrum, Base, etc.)
- Solana (SVM)

The `ChainClient` abstract base class defines the common interface, while
`EVMClient` and `SolanaClient` provide chain-specific implementations.

Example:
    >>> from sentinel_keeper.chain import EVMClient, SolanaClient
    >>>
    >>> # For EVM chains
    >>> evm_client = EVMClient(rpc_url="...", private_key="...", ...)
    >>> await evm_client.connect()
    >>>
    >>> # For Solana
    >>> svm_client = SolanaClient(rpc_url="...", private_key_path="...", ...)
    >>> await svm_client.connect()
"""

from sentinel_keeper.chain.base import (
    ChainClient,
    ChainClientError,
    ConnectionError,
    ExecutionError,
    PriceUnavailableError,
    TransactionFailedError,
)
from sentinel_keeper.chain.evm import EVMClient
from sentinel_keeper.chain.svm import SolanaClient

__all__ = [
    # Base classes
    "ChainClient",
    # Implementations
    "EVMClient",
    "SolanaClient",
    # Exceptions
    "ChainClientError",
    "ConnectionError",
    "ExecutionError",
    "PriceUnavailableError",
    "TransactionFailedError",
]
