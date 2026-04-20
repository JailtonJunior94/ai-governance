"""Payment domain: entity, value objects and invariants."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum


class InvalidTransitionError(Exception):
    """Raised when a status transition is not allowed."""


@dataclass(frozen=True)
class Money:
    """Value object representing a monetary amount with currency."""

    amount: int
    currency: str

    def __post_init__(self) -> None:
        if self.amount < 0:
            raise ValueError("amount must be non-negative")
        if not self.currency:
            raise ValueError("currency is required")


class PaymentStatus(str, Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    CANCELLED = "cancelled"


@dataclass
class Payment:
    """Aggregate root for the payment domain."""

    id: str
    customer_id: str
    amount: Money
    status: PaymentStatus = field(default=PaymentStatus.PENDING)
    created_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    def __post_init__(self) -> None:
        if not self.id:
            raise ValueError("id is required")
        if not self.customer_id:
            raise ValueError("customer_id is required")

    def confirm(self) -> None:
        if self.status != PaymentStatus.PENDING:
            raise InvalidTransitionError(
                f"cannot confirm from {self.status.value}"
            )
        self.status = PaymentStatus.CONFIRMED

    def cancel(self) -> None:
        if self.status == PaymentStatus.CANCELLED:
            raise InvalidTransitionError("already cancelled")
        self.status = PaymentStatus.CANCELLED
