# 🤖 Keeper Documentation

> Off-chain keeper bot for Sentinel Protocol

---

## Overview

The Sentinel Keeper is a Python-based off-chain service that:

1. **Monitors** the blockchain for new orders
2. **Evaluates** trigger conditions (price, time)
3. **Executes** orders when conditions are met
4. **Reports** metrics and logs for observability

---

## Architecture

```
keeper/
├── sentinel_keeper/
│   ├── __init__.py
│   ├── app.py              # KeeperService entrypoint
│   ├── config.py           # Settings (pydantic-settings)
│   ├── main.py             # CLI entrypoint
│   │
│   ├── chain/              # Blockchain layer
│   │   ├── __init__.py
│   │   ├── client.py       # ChainClient (Web3 wrapper)
│   │   ├── events.py       # EventIndexer
│   │   └── tx.py           # TransactionManager
│   │
│   ├── strategies/         # Strategy evaluation
│   │   ├── __init__.py
│   │   ├── base.py         # BaseStrategy (ABC)
│   │   ├── stoploss.py     # StopLossStrategy
│   │   └── twap.py         # TWAPStrategy
│   │
│   ├── executors/          # Order execution
│   │   ├── __init__.py
│   │   ├── order_executor.py  # OrderExecutor
│   │   └── retry.py        # Retry with backoff
│   │
│   ├── models/             # Data models
│   │   ├── __init__.py
│   │   └── order.py        # Pydantic Order model
│   │
│   └── observability/      # Logging & metrics
│       ├── __init__.py
│       ├── logger.py       # structlog configuration
│       └── metrics.py      # MetricsCollector
│
├── tests/
│   └── ...
└── pyproject.toml
```

---

## Components

### KeeperService (`app.py`)

Main application loop:

```python
class KeeperService:
    """Main keeper application service."""

    async def start(self) -> None:
        """Start the keeper service."""
        # Initialize components
        # Enter main loop

    async def stop(self) -> None:
        """Graceful shutdown."""

    async def _run_loop(self) -> None:
        """Poll blocks, evaluate orders, execute."""
```

### ChainClient (`chain/client.py`)

Web3 provider wrapper:

```python
class ChainClient:
    """Blockchain connectivity layer."""

    async def get_block(self, block_number: int) -> Block:
        """Fetch block by number."""

    async def get_order(self, order_id: int) -> Order:
        """Fetch order from contract."""

    async def get_price(self, oracle: str, base: str, quote: str) -> int:
        """Get current price from oracle."""
```

### EventIndexer (`chain/events.py`)

Event subscription and indexing:

```python
class EventIndexer:
    """Indexes blockchain events."""

    async def subscribe(self, from_block: int) -> None:
        """Start event subscription."""

    async def get_open_orders(self) -> list[int]:
        """Get all open order IDs."""
```

### TransactionManager (`chain/tx.py`)

Transaction submission with nonce management:

```python
class TransactionManager:
    """Manages transaction lifecycle."""

    async def submit(self, tx: Transaction) -> TxReceipt:
        """Submit transaction to chain."""

    async def wait_for_confirmation(self, tx_hash: str) -> TxReceipt:
        """Wait for transaction confirmation."""
```

### Strategies (`strategies/`)

Strategy pattern for order evaluation:

```python
class BaseStrategy(ABC):
    """Abstract base for strategies."""

    @abstractmethod
    async def should_execute(self, order: Order) -> bool:
        """Check if order should be executed."""

class StopLossStrategy(BaseStrategy):
    """Stop-loss strategy: execute when price <= target."""

    async def should_execute(self, order: Order) -> bool:
        current_price = await self.chain.get_price(...)
        return current_price <= order.trigger.target_price
```

### OrderExecutor (`executors/order_executor.py`)

Coordinates order execution:

```python
class OrderExecutor:
    """Executes orders on-chain."""

    async def execute(self, order_id: int) -> TxReceipt:
        """Execute a single order."""

    async def execute_batch(self, order_ids: list[int]) -> list[TxReceipt]:
        """Execute multiple orders."""
```

---

## Configuration

### Environment Variables

| Variable             | Description                    | Default                 |
| -------------------- | ------------------------------ | ----------------------- |
| `RPC_URL`            | Ethereum RPC endpoint          | `http://localhost:8545` |
| `CHAIN_ID`           | Chain ID                       | `31337`                 |
| `VAULT_ADDRESS`      | SentinelVault contract address | Required                |
| `KEEPER_PRIVATE_KEY` | Keeper wallet private key      | Required                |
| `POLL_INTERVAL`      | Block polling interval (sec)   | `12`                    |
| `MAX_GAS_PRICE`      | Max gas price (gwei)           | `100`                   |
| `LOG_LEVEL`          | Logging level                  | `INFO`                  |

### Example `.env`

```bash
# Network
RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
CHAIN_ID=1

# Contract
VAULT_ADDRESS=0x1234567890abcdef...

# Keeper wallet
KEEPER_PRIVATE_KEY=0xabcdef...

# Execution
POLL_INTERVAL=12
MAX_GAS_PRICE=50

# Observability
LOG_LEVEL=INFO
```

### Settings Class

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    """Application settings."""

    rpc_url: str = "http://localhost:8545"
    chain_id: int = 31337
    vault_address: str
    keeper_private_key: str
    poll_interval: int = 12
    max_gas_price: int = 100
    log_level: str = "INFO"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
    )
```

---

## Models

### Order Model (`models/order.py`)

```python
from enum import IntEnum
from pydantic import BaseModel

class OrderKind(IntEnum):
    STOP_LOSS = 0
    TAKE_PROFIT = 1
    TWAP = 2

class OrderState(IntEnum):
    OPEN = 0
    EXECUTED = 1
    CANCELLED = 2
    EXPIRED = 3

class Trigger(BaseModel):
    oracle: str
    target_price: int  # 1e18 scale
    deadline: int      # Unix timestamp

class Execution(BaseModel):
    input_token: str
    output_token: str
    input_amount: int
    min_output_amount: int
    slippage_bps: int

class Order(BaseModel):
    id: int
    owner: str
    kind: OrderKind
    state: OrderState
    trigger: Trigger
    execution: Execution
    created_at: int
```

---

## Observability

### Structured Logging

Using `structlog` for structured logs:

```python
import structlog

log = structlog.get_logger()

# Good - structured
log.info("order_executed", order_id=123, keeper="0x...", gas_used=150000)

# Bad - unstructured
log.info(f"Executed order {order_id}")
```

### Log Levels

| Level   | Usage                             |
| ------- | --------------------------------- |
| DEBUG   | Detailed debugging information    |
| INFO    | Normal operation events           |
| WARNING | Unexpected but handled situations |
| ERROR   | Errors requiring attention        |

### Metrics

```python
class MetricsCollector:
    """Collects and exposes metrics."""

    def record_execution(self, order_id: int, success: bool, gas: int):
        """Record order execution."""

    def record_poll(self, block_number: int, orders_found: int):
        """Record block poll."""
```

---

## Running

### Development

```bash
cd keeper

# Install dependencies
uv sync

# Run keeper
uv run python -m sentinel_keeper.main

# Or with make
make keeper-local
```

### Docker

```bash
# Build image
docker build -t sentinel-keeper -f keeper/Dockerfile .

# Run container
docker run --env-file keeper/.env sentinel-keeper
```

### Docker Compose

```bash
# Start all services (anvil + keeper)
docker-compose up

# Keeper only
docker-compose up keeper
```

---

## Testing

### Unit Tests

```bash
cd keeper
uv run pytest
```

### Coverage

```bash
uv run pytest --cov=sentinel_keeper --cov-report=html
```

### Integration Tests

```bash
# Start local anvil first
anvil &

# Run integration tests
uv run pytest tests/integration/
```

---

## Execution Flow

### Normal Flow

```
1. KeeperService.start()
   │
2. EventIndexer.subscribe(from_block)
   │
3. Loop:
   │
   ├─► Poll new blocks
   │   │
   │   ├─► Index OrderCreated events
   │   │
   │   └─► For each open order:
   │       │
   │       ├─► Strategy.should_execute(order)
   │       │   │
   │       │   └─► Check price vs trigger
   │       │
   │       └─► If yes: OrderExecutor.execute(order_id)
   │           │
   │           ├─► Build transaction
   │           ├─► Submit to chain
   │           └─► Wait for confirmation
   │
   └─► Sleep(poll_interval)
```

### Error Handling

```python
@with_retry(max_attempts=3, backoff_factor=2)
async def execute(self, order_id: int) -> TxReceipt:
    """Execute with automatic retry."""
    try:
        return await self._submit_execution(order_id)
    except TransactionRevertedError as e:
        log.error("execution_reverted", order_id=order_id, error=str(e))
        raise
    except GasTooHighError:
        log.warning("gas_too_high", order_id=order_id)
        raise  # Will be retried
```

---

## Security Considerations

### Private Key Management

- **Never** commit private keys to git
- Use environment variables or secret managers
- Consider hardware wallets for production

### Gas Management

- Set `MAX_GAS_PRICE` to prevent overpaying
- Monitor gas prices before execution
- Implement gas estimation before submission

### Error Handling

- Retry transient failures with backoff
- Alert on persistent failures
- Log all execution attempts

---

## Monitoring

### Recommended Alerts

| Alert             | Condition                |
| ----------------- | ------------------------ |
| Keeper Offline    | No polls for 5 minutes   |
| Execution Failure | 3+ consecutive failures  |
| High Gas Usage    | Gas price > threshold    |
| Balance Low       | Keeper ETH balance < 0.1 |

### Health Check

```python
@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "last_block": indexer.last_block,
        "pending_orders": len(executor.pending),
    }
```

---

## Troubleshooting

### Common Issues

**1. RPC Connection Failed**

```
Error: Could not connect to RPC
Solution: Check RPC_URL and network connectivity
```

**2. Insufficient Gas**

```
Error: Transaction underpriced
Solution: Increase MAX_GAS_PRICE or wait for lower gas
```

**3. Nonce Too Low**

```
Error: Nonce already used
Solution: Restart keeper to resync nonce
```

**4. Order Already Executed**

```
Error: OrderNotOpen
Solution: Normal if another keeper executed first
```
