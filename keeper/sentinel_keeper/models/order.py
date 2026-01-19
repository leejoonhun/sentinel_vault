"""Order models.

Pydantic models matching on-chain Order struct.
"""

from enum import IntEnum

from pydantic import BaseModel, Field


class OrderKind(IntEnum):
    """Order kind matching on-chain enum."""

    STOP_LOSS = 0
    TAKE_PROFIT = 1
    TWAP = 2


class OrderState(IntEnum):
    """Order state matching on-chain enum."""

    OPEN = 0
    EXECUTED = 1
    CANCELLED = 2
    EXPIRED = 3


class Trigger(BaseModel):
    """Trigger conditions for order execution."""

    oracle: str = Field(..., description="Price oracle address")
    target_price: int = Field(..., description="Target price (1e18 scale)")
    deadline: int = Field(..., description="Order expiration timestamp")


class Execution(BaseModel):
    """Execution parameters for order."""

    input_token: str = Field(..., description="Token to sell")
    output_token: str = Field(..., description="Token to buy")
    input_amount: int = Field(..., description="Amount to sell")
    min_output_amount: int = Field(..., description="Minimum amount to receive")
    slippage_bps: int = Field(..., description="Slippage tolerance in basis points")


class Order(BaseModel):
    """Complete order model matching on-chain struct."""

    id: int = Field(..., description="Order identifier")
    owner: str = Field(..., description="Order owner address")
    kind: OrderKind = Field(..., description="Order type")
    state: OrderState = Field(..., description="Current order state")
    trigger: Trigger = Field(..., description="Trigger conditions")
    execution: Execution = Field(..., description="Execution parameters")
    created_at: int = Field(..., description="Creation timestamp")

    @classmethod
    def from_chain(cls, data: tuple) -> "Order":
        """Create Order from on-chain tuple.

        Args:
            data: Tuple returned from contract call.

        Returns:
            Order instance.
        """
        (
            order_id,
            owner,
            kind,
            state,
            (oracle, target_price, deadline),
            (input_token, output_token, input_amount, min_output, slippage),
            created_at,
        ) = data

        return cls(
            id=order_id,
            owner=owner,
            kind=OrderKind(kind),
            state=OrderState(state),
            trigger=Trigger(
                oracle=oracle,
                target_price=target_price,
                deadline=deadline,
            ),
            execution=Execution(
                input_token=input_token,
                output_token=output_token,
                input_amount=input_amount,
                min_output_amount=min_output,
                slippage_bps=slippage,
            ),
            created_at=created_at,
        )
