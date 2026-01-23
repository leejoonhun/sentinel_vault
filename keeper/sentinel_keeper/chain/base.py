"""Abstract base class for blockchain clients.

This module defines the interface that all chain-specific clients must implement.
The abstraction allows the Keeper to interact with different blockchains
(EVM, Solana, etc.) through a unified API.
"""

from abc import ABC, abstractmethod
from decimal import Decimal
from typing import Any

from sentinel_keeper.models.order import Order, OrderStatus, OrderType


class ChainClient(ABC):
    """Abstract base class for blockchain client implementations.

    All chain-specific clients (EVM, Solana, etc.) must implement this interface.
    This enables the Keeper to be chain-agnostic and support multiple blockchains
    through a single codebase.

    Example:
        >>> client = EVMClient(config)  # or SolanaClient(config)
        >>> price = await client.get_price("ETH/USDC")
        >>> orders = await client.get_active_orders(vault_address)
    """

    @abstractmethod
    async def connect(self) -> None:
        """Establish connection to the blockchain network.

        Raises:
            ConnectionError: If unable to connect to the RPC endpoint.
        """
        ...

    @abstractmethod
    async def disconnect(self) -> None:
        """Gracefully close the connection to the blockchain."""
        ...

    @abstractmethod
    async def is_connected(self) -> bool:
        """Check if the client is connected to the blockchain.

        Returns:
            True if connected, False otherwise.
        """
        ...

    # =========================================================================
    # Price & Market Data
    # =========================================================================

    @abstractmethod
    async def get_price(self, pair: str) -> Decimal:
        """Fetch the current price for a trading pair.

        Args:
            pair: Trading pair in format "BASE/QUOTE" (e.g., "ETH/USDC").

        Returns:
            Current price as a Decimal.

        Raises:
            PriceUnavailableError: If price cannot be fetched.
        """
        ...

    @abstractmethod
    async def get_oracle_price(self, oracle_address: str) -> Decimal:
        """Fetch price from a specific oracle contract/account.

        Args:
            oracle_address: Address of the oracle contract/account.

        Returns:
            Oracle price as a Decimal.
        """
        ...

    # =========================================================================
    # Order Management
    # =========================================================================

    @abstractmethod
    async def get_active_orders(self, vault_address: str) -> list[Order]:
        """Retrieve all active orders for a vault.

        Args:
            vault_address: Address of the vault contract/account.

        Returns:
            List of active Order objects.
        """
        ...

    @abstractmethod
    async def get_order(self, vault_address: str, order_id: int) -> Order | None:
        """Retrieve a specific order by ID.

        Args:
            vault_address: Address of the vault.
            order_id: Unique order identifier.

        Returns:
            Order object if found, None otherwise.
        """
        ...

    @abstractmethod
    async def execute_order(
        self,
        vault_address: str,
        order_id: int,
        *,
        gas_price: int | None = None,
    ) -> str:
        """Execute an order on-chain.

        Args:
            vault_address: Address of the vault.
            order_id: Order to execute.
            gas_price: Optional gas price override (for EVM chains).

        Returns:
            Transaction hash/signature.

        Raises:
            ExecutionError: If order execution fails.
        """
        ...

    # =========================================================================
    # Account & Balance
    # =========================================================================

    @abstractmethod
    async def get_balance(self, address: str, token: str | None = None) -> Decimal:
        """Get the balance of an address.

        Args:
            address: Wallet/account address.
            token: Token mint/contract address. If None, returns native balance.

        Returns:
            Balance as a Decimal.
        """
        ...

    @abstractmethod
    async def get_vault_balance(
        self, vault_address: str, token: str | None = None
    ) -> Decimal:
        """Get the balance held in a vault.

        Args:
            vault_address: Vault contract/account address.
            token: Token to query. If None, returns native balance.

        Returns:
            Vault balance as a Decimal.
        """
        ...

    # =========================================================================
    # Transaction Management
    # =========================================================================

    @abstractmethod
    async def send_transaction(
        self,
        to: str,
        data: bytes,
        value: int = 0,
        *,
        gas_limit: int | None = None,
        gas_price: int | None = None,
    ) -> str:
        """Send a raw transaction to the blockchain.

        Args:
            to: Destination address.
            data: Transaction calldata.
            value: Native token value to send.
            gas_limit: Maximum gas to use.
            gas_price: Gas price (wei for EVM, lamports for Solana).

        Returns:
            Transaction hash/signature.
        """
        ...

    @abstractmethod
    async def wait_for_transaction(
        self, tx_hash: str, timeout: float = 60.0
    ) -> dict[str, Any]:
        """Wait for a transaction to be confirmed.

        Args:
            tx_hash: Transaction hash/signature to wait for.
            timeout: Maximum time to wait in seconds.

        Returns:
            Transaction receipt/confirmation data.

        Raises:
            TimeoutError: If transaction is not confirmed within timeout.
            TransactionFailedError: If transaction reverts/fails.
        """
        ...

    @abstractmethod
    async def estimate_gas(self, to: str, data: bytes, value: int = 0) -> int:
        """Estimate gas/compute units for a transaction.

        Args:
            to: Destination address.
            data: Transaction calldata.
            value: Native token value.

        Returns:
            Estimated gas/compute units.
        """
        ...

    # =========================================================================
    # Chain Info
    # =========================================================================

    @property
    @abstractmethod
    def chain_id(self) -> int | str:
        """Get the chain identifier.

        Returns:
            Chain ID (int for EVM, str for Solana cluster).
        """
        ...

    @property
    @abstractmethod
    def chain_name(self) -> str:
        """Human-readable chain name (e.g., 'Ethereum', 'Solana')."""
        ...

    @abstractmethod
    async def get_block_number(self) -> int:
        """Get the current block/slot number.

        Returns:
            Latest block number (EVM) or slot (Solana).
        """
        ...


class ChainClientError(Exception):
    """Base exception for chain client errors."""

    pass


class ConnectionError(ChainClientError):
    """Failed to connect to blockchain RPC."""

    pass


class PriceUnavailableError(ChainClientError):
    """Unable to fetch price data."""

    pass


class ExecutionError(ChainClientError):
    """Order execution failed."""

    pass


class TransactionFailedError(ChainClientError):
    """Transaction reverted or failed."""

    pass
