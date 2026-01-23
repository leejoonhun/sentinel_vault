"""EVM (Ethereum Virtual Machine) chain client implementation.

This module provides the concrete implementation of ChainClient for EVM-compatible
blockchains including Ethereum, Arbitrum, Base, Optimism, and other L2s.

Uses web3.py for blockchain interaction.
"""

from decimal import Decimal
from typing import Any

from sentinel_keeper.chain.base import (
    ChainClient,
    ChainClientError,
    ConnectionError,
    ExecutionError,
    PriceUnavailableError,
    TransactionFailedError,
)
from sentinel_keeper.models.order import Order, OrderStatus, OrderType

# NOTE: web3.py import is deferred to avoid import errors if not installed
# from web3 import AsyncWeb3
# from web3.types import TxParams, TxReceipt


class EVMClient(ChainClient):
    """EVM blockchain client using web3.py.

    Supports Ethereum mainnet, testnets, and L2s like Arbitrum/Base.

    Example:
        >>> config = EVMClientConfig(
        ...     rpc_url="https://arb1.arbitrum.io/rpc",
        ...     chain_id=42161,
        ...     private_key="0x...",
        ...     vault_address="0x...",
        ... )
        >>> client = EVMClient(config)
        >>> await client.connect()
        >>> price = await client.get_price("ETH/USDC")
    """

    def __init__(
        self,
        rpc_url: str,
        private_key: str,
        vault_address: str,
        chain_id: int,
        *,
        chain_name: str = "EVM",
    ) -> None:
        """Initialize EVM client.

        Args:
            rpc_url: HTTP/WebSocket RPC endpoint URL.
            private_key: Keeper's private key for signing transactions.
            vault_address: SentinelVault contract address.
            chain_id: EVM chain ID.
            chain_name: Human-readable chain name.
        """
        self._rpc_url = rpc_url
        self._private_key = private_key
        self._vault_address = vault_address
        self._chain_id = chain_id
        self._chain_name = chain_name

        self._web3: Any = None  # AsyncWeb3 instance
        self._account: Any = None
        self._vault_contract: Any = None

    async def connect(self) -> None:
        """Establish connection to EVM RPC endpoint."""
        try:
            from web3 import AsyncWeb3
            from web3.middleware import ExtraDataToPOAMiddleware

            # Create AsyncWeb3 instance
            if self._rpc_url.startswith("ws"):
                from web3 import WebSocketProvider

                self._web3 = AsyncWeb3(WebSocketProvider(self._rpc_url))
            else:
                from web3 import AsyncHTTPProvider

                self._web3 = AsyncWeb3(AsyncHTTPProvider(self._rpc_url))

            # Add POA middleware for L2 chains
            self._web3.middleware_onion.inject(ExtraDataToPOAMiddleware, layer=0)

            # Setup account from private key
            self._account = self._web3.eth.account.from_key(self._private_key)

            # Verify connection
            if not await self._web3.is_connected():
                raise ConnectionError(f"Failed to connect to {self._rpc_url}")

            # TODO: Load vault contract ABI and create contract instance
            # self._vault_contract = self._web3.eth.contract(
            #     address=self._vault_address,
            #     abi=VAULT_ABI
            # )

        except ImportError as e:
            raise ConnectionError("web3.py not installed. Run: pip install web3") from e
        except Exception as e:
            raise ConnectionError(f"Connection failed: {e}") from e

    async def disconnect(self) -> None:
        """Close the web3 connection."""
        if self._web3 and hasattr(self._web3.provider, "disconnect"):
            await self._web3.provider.disconnect()
        self._web3 = None

    async def is_connected(self) -> bool:
        """Check if connected to the RPC endpoint."""
        if self._web3 is None:
            return False
        return await self._web3.is_connected()

    # =========================================================================
    # Price & Market Data
    # =========================================================================

    async def get_price(self, pair: str) -> Decimal:
        """Fetch price from Chainlink or other oracle.

        Args:
            pair: Trading pair (e.g., "ETH/USDC").

        Returns:
            Current price.
        """
        # TODO: Implement Chainlink price feed integration
        # For now, raise not implemented
        raise NotImplementedError("Price feed integration pending")

    async def get_oracle_price(self, oracle_address: str) -> Decimal:
        """Fetch price from a Chainlink oracle.

        Args:
            oracle_address: Chainlink aggregator contract address.

        Returns:
            Latest oracle price.
        """
        # TODO: Call Chainlink latestRoundData()
        raise NotImplementedError("Oracle price feed pending")

    # =========================================================================
    # Order Management
    # =========================================================================

    async def get_active_orders(self, vault_address: str) -> list[Order]:
        """Get all active orders from the vault contract.

        Args:
            vault_address: SentinelVault contract address.

        Returns:
            List of active orders.
        """
        # TODO: Call vault.getActiveOrders() and parse results
        raise NotImplementedError("Order fetching pending")

    async def get_order(self, vault_address: str, order_id: int) -> Order | None:
        """Get a specific order by ID.

        Args:
            vault_address: Vault address.
            order_id: Order ID.

        Returns:
            Order if found.
        """
        # TODO: Call vault.getOrder(orderId)
        raise NotImplementedError("Order fetching pending")

    async def execute_order(
        self,
        vault_address: str,
        order_id: int,
        *,
        gas_price: int | None = None,
    ) -> str:
        """Execute an order on the vault contract.

        Args:
            vault_address: Vault contract address.
            order_id: Order to execute.
            gas_price: Optional gas price in wei.

        Returns:
            Transaction hash.
        """
        if not self._web3 or not self._account:
            raise ChainClientError("Client not connected")

        # TODO: Build and send executeOrder transaction
        # tx = await self._vault_contract.functions.executeOrder(order_id).build_transaction({
        #     'from': self._account.address,
        #     'gas': 500000,
        #     'gasPrice': gas_price or await self._web3.eth.gas_price,
        #     'nonce': await self._web3.eth.get_transaction_count(self._account.address),
        # })
        # signed = self._account.sign_transaction(tx)
        # tx_hash = await self._web3.eth.send_raw_transaction(signed.rawTransaction)
        # return tx_hash.hex()

        raise NotImplementedError("Order execution pending")

    # =========================================================================
    # Account & Balance
    # =========================================================================

    async def get_balance(self, address: str, token: str | None = None) -> Decimal:
        """Get balance of an address.

        Args:
            address: Wallet address.
            token: ERC20 token address (None for ETH).

        Returns:
            Balance in token units.
        """
        if not self._web3:
            raise ChainClientError("Client not connected")

        if token is None:
            # Native ETH balance
            balance_wei = await self._web3.eth.get_balance(address)
            return Decimal(balance_wei) / Decimal(10**18)
        else:
            # TODO: Call ERC20 balanceOf
            raise NotImplementedError("ERC20 balance pending")

    async def get_vault_balance(
        self, vault_address: str, token: str | None = None
    ) -> Decimal:
        """Get balance held in the vault."""
        return await self.get_balance(vault_address, token)

    # =========================================================================
    # Transaction Management
    # =========================================================================

    async def send_transaction(
        self,
        to: str,
        data: bytes,
        value: int = 0,
        *,
        gas_limit: int | None = None,
        gas_price: int | None = None,
    ) -> str:
        """Send a raw transaction.

        Args:
            to: Destination address.
            data: Calldata.
            value: ETH value in wei.
            gas_limit: Gas limit.
            gas_price: Gas price in wei.

        Returns:
            Transaction hash.
        """
        if not self._web3 or not self._account:
            raise ChainClientError("Client not connected")

        tx = {
            "to": to,
            "data": data,
            "value": value,
            "gas": gas_limit or 100000,
            "gasPrice": gas_price or await self._web3.eth.gas_price,
            "nonce": await self._web3.eth.get_transaction_count(self._account.address),
            "chainId": self._chain_id,
        }

        signed = self._account.sign_transaction(tx)
        tx_hash = await self._web3.eth.send_raw_transaction(signed.rawTransaction)
        return tx_hash.hex()

    async def wait_for_transaction(
        self, tx_hash: str, timeout: float = 60.0
    ) -> dict[str, Any]:
        """Wait for transaction confirmation.

        Args:
            tx_hash: Transaction hash.
            timeout: Timeout in seconds.

        Returns:
            Transaction receipt.
        """
        if not self._web3:
            raise ChainClientError("Client not connected")

        import asyncio

        receipt = await asyncio.wait_for(
            self._web3.eth.wait_for_transaction_receipt(tx_hash),
            timeout=timeout,
        )

        if receipt["status"] == 0:
            raise TransactionFailedError(f"Transaction {tx_hash} reverted")

        return dict(receipt)

    async def estimate_gas(self, to: str, data: bytes, value: int = 0) -> int:
        """Estimate gas for a transaction.

        Args:
            to: Destination address.
            data: Calldata.
            value: ETH value.

        Returns:
            Estimated gas.
        """
        if not self._web3:
            raise ChainClientError("Client not connected")

        return await self._web3.eth.estimate_gas(
            {"to": to, "data": data, "value": value, "from": self._account.address}
        )

    # =========================================================================
    # Chain Info
    # =========================================================================

    @property
    def chain_id(self) -> int:
        """EVM chain ID."""
        return self._chain_id

    @property
    def chain_name(self) -> str:
        """Human-readable chain name."""
        return self._chain_name

    async def get_block_number(self) -> int:
        """Get the latest block number."""
        if not self._web3:
            raise ChainClientError("Client not connected")
        return await self._web3.eth.block_number
