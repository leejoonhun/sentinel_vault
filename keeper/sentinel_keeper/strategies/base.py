"""Base Strategy.

Abstract base class for all strategies.
"""

from abc import ABC, abstractmethod

from ..models.order import Order


class BaseStrategy(ABC):
    """Abstract base class for order evaluation strategies."""

    @abstractmethod
    def should_execute(self, order: Order, current_price: int) -> bool:
        """Determine if an order should be executed.

        Args:
            order: Order to evaluate.
            current_price: Current price from oracle (1e18 scale).

        Returns:
            True if the order should be executed.
        """
        pass

    @abstractmethod
    def get_name(self) -> str:
        """Get strategy name.

        Returns:
            Strategy identifier.
        """
        pass
