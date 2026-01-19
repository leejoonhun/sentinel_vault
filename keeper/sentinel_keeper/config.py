"""Configuration.

Environment-based configuration using pydantic-settings.
"""

from functools import lru_cache
from typing import Literal

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # Network
    rpc_url: str = Field(
        default="http://localhost:8545",
        description="RPC endpoint URL",
    )
    chain_id: int = Field(
        default=31337,
        description="Chain ID",
    )

    # Contracts
    vault_address: str = Field(
        default="",
        description="SentinelVault contract address",
    )

    # Keeper
    keeper_private_key: str = Field(
        default="",
        description="Keeper wallet private key",
    )
    poll_interval: int = Field(
        default=12,
        description="Block polling interval in seconds",
    )
    max_gas_price_gwei: int = Field(
        default=100,
        description="Maximum gas price willing to pay",
    )

    # Flashbots
    use_flashbots: bool = Field(
        default=False,
        description="Enable Flashbots for MEV protection",
    )
    flashbots_relay_url: str = Field(
        default="https://relay.flashbots.net",
        description="Flashbots relay URL",
    )

    # Logging
    log_level: str = Field(
        default="INFO",
        description="Log level",
    )
    log_format: Literal["json", "console"] = Field(
        default="console",
        description="Log output format",
    )


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance.

    Returns:
        Application settings.
    """

    return Settings()
