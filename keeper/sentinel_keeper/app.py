"""Main Application.

Entry point for the keeper service.
"""

import asyncio
import signal

from sentinel_keeper.config import get_settings
from sentinel_keeper.observability.logger import configure_logging, get_logger

log = get_logger()


class KeeperService:
    """Main keeper application service."""

    def __init__(self) -> None:
        """Initialize keeper service."""
        self.settings = get_settings()
        self._running = False

    async def start(self) -> None:
        """Start the keeper service."""
        log.keeper_starting(
            chain_id=self.settings.chain_id,
            vault_address=self.settings.vault_address,
        )

        self._running = True

        # TODO: Initialize chain client, event indexer, executor

        await self._run_loop()

    async def stop(self) -> None:
        """Stop the keeper service."""
        log.keeper_stopping()
        self._running = False

    async def _run_loop(self) -> None:
        """Main event loop."""
        while self._running:
            try:
                # TODO: Poll blocks, check orders, execute if ready
                await asyncio.sleep(self.settings.poll_interval)
            except Exception as e:
                log.error("loop_error", error=str(e))
                await asyncio.sleep(5)


async def async_main() -> None:
    """Async entry point."""
    settings = get_settings()
    configure_logging(
        level=settings.log_level,
        format=settings.log_format,
    )

    service = KeeperService()

    # Handle shutdown signals
    loop = asyncio.get_running_loop()

    def shutdown_handler() -> None:
        log.info("Shutdown signal received")
        asyncio.create_task(service.stop())

    for sig in (signal.SIGINT, signal.SIGTERM):
        loop.add_signal_handler(sig, shutdown_handler)

    await service.start()


def main() -> None:
    """Main entry point."""
    asyncio.run(async_main())


if __name__ == "__main__":
    main()
