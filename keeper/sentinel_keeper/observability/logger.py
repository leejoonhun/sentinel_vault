"""Logger configuration.

Rich-based structured logging for beautiful terminal output.
"""

import logging
import sys
from typing import Literal

from rich.console import Console
from rich.logging import RichHandler
from rich.theme import Theme

# Custom theme for keeper logs
KEEPER_THEME = Theme(
    {
        "info": "cyan",
        "warning": "yellow",
        "error": "bold red",
        "critical": "bold white on red",
        "debug": "dim",
        "keeper": "bold green",
        "order": "bold magenta",
        "tx": "bold blue",
    }
)

# Global console instance
console = Console(theme=KEEPER_THEME)


def configure_logging(
    level: str = "INFO",
    format: Literal["json", "console"] = "console",
) -> None:
    """Configure Rich-based logging.

    Args:
        level: Log level (DEBUG, INFO, WARNING, ERROR).
        format: Output format (json for production, console for development).
    """
    log_level = getattr(logging, level.upper(), logging.INFO)

    if format == "json":
        # Production: JSON format (no Rich formatting)
        logging.basicConfig(
            level=log_level,
            format='{"time": "%(asctime)s", "level": "%(levelname)s", "name": "%(name)s", "message": "%(message)s"}',
            datefmt="%Y-%m-%dT%H:%M:%S",
            stream=sys.stdout,
        )
    else:
        # Development: Rich console output
        logging.basicConfig(
            level=log_level,
            format="%(message)s",
            datefmt="[%X]",
            handlers=[
                RichHandler(
                    console=console,
                    rich_tracebacks=True,
                    tracebacks_show_locals=True,
                    show_time=True,
                    show_path=True,
                    markup=True,
                )
            ],
        )

    # Suppress noisy third-party loggers
    logging.getLogger("httpx").setLevel(logging.WARNING)
    logging.getLogger("httpcore").setLevel(logging.WARNING)
    logging.getLogger("web3").setLevel(logging.WARNING)
    logging.getLogger("urllib3").setLevel(logging.WARNING)


class KeeperLogger:
    """Structured logger with Rich formatting support."""

    def __init__(self, name: str = "sentinel_keeper") -> None:
        """Initialize logger.

        Args:
            name: Logger name.
        """
        self._logger = logging.getLogger(name)
        self._console = console

    def _format_extras(self, **kwargs: object) -> str:
        """Format extra fields for structured logging."""
        if not kwargs:
            return ""
        parts = [f"[dim]{k}=[/dim]{v}" for k, v in kwargs.items()]
        return " " + " ".join(parts)

    def debug(self, msg: str, **kwargs: object) -> None:
        """Log debug message."""
        self._logger.debug(f"{msg}{self._format_extras(**kwargs)}")

    def info(self, msg: str, **kwargs: object) -> None:
        """Log info message."""
        self._logger.info(f"{msg}{self._format_extras(**kwargs)}")

    def warning(self, msg: str, **kwargs: object) -> None:
        """Log warning message."""
        self._logger.warning(f"{msg}{self._format_extras(**kwargs)}")

    def error(self, msg: str, **kwargs: object) -> None:
        """Log error message."""
        self._logger.error(f"{msg}{self._format_extras(**kwargs)}")

    def critical(self, msg: str, **kwargs: object) -> None:
        """Log critical message."""
        self._logger.critical(f"{msg}{self._format_extras(**kwargs)}")

    # Domain-specific log methods
    def order_created(self, order_id: int, owner: str, kind: str) -> None:
        """Log order creation."""
        self._logger.info(
            f"[order]Order created[/order] [dim]id=[/dim]{order_id} "
            f"[dim]owner=[/dim]{owner[:10]}... [dim]kind=[/dim]{kind}"
        )

    def order_executed(
        self, order_id: int, keeper: str, gas_used: int, amount_out: int
    ) -> None:
        """Log order execution."""
        self._logger.info(
            f"[tx]Order executed[/tx] [dim]id=[/dim]{order_id} "
            f"[dim]keeper=[/dim]{keeper[:10]}... [dim]gas=[/dim]{gas_used} "
            f"[dim]out=[/dim]{amount_out}"
        )

    def keeper_starting(self, chain_id: int, vault_address: str) -> None:
        """Log keeper startup."""
        self._logger.info(
            f"[keeper]Keeper starting[/keeper] [dim]chain=[/dim]{chain_id} "
            f"[dim]vault=[/dim]{vault_address[:10]}..."
        )

    def keeper_stopping(self) -> None:
        """Log keeper shutdown."""
        self._logger.info("[keeper]Keeper stopping[/keeper]")

    def block_polled(self, block_number: int, orders_found: int) -> None:
        """Log block polling."""
        self._logger.debug(
            f"Block polled [dim]number=[/dim]{block_number} "
            f"[dim]orders=[/dim]{orders_found}"
        )

    def tx_submitted(self, tx_hash: str, nonce: int) -> None:
        """Log transaction submission."""
        self._logger.info(
            f"[tx]Transaction submitted[/tx] [dim]hash=[/dim]{tx_hash[:10]}... "
            f"[dim]nonce=[/dim]{nonce}"
        )

    def tx_confirmed(self, tx_hash: str, gas_used: int) -> None:
        """Log transaction confirmation."""
        self._logger.info(
            f"[tx]Transaction confirmed[/tx] [dim]hash=[/dim]{tx_hash[:10]}... "
            f"[dim]gas=[/dim]{gas_used}"
        )

    def tx_failed(self, tx_hash: str, error: str) -> None:
        """Log transaction failure."""
        self._logger.error(
            f"[tx]Transaction failed[/tx] [dim]hash=[/dim]{tx_hash[:10]}... "
            f"[dim]error=[/dim]{error}"
        )


def get_logger(name: str | None = None) -> KeeperLogger:
    """Get a logger instance.

    Args:
        name: Optional logger name.

    Returns:
        Configured KeeperLogger.
    """
    return KeeperLogger(name or "sentinel_keeper")
