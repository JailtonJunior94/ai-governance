"""Repository interface for the payment aggregate."""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Optional

from .entity import Payment, PaymentStatus


@dataclass(frozen=True)
class PaymentFilter:
    customer_id: Optional[str] = None
    status: Optional[PaymentStatus] = None
    page: int = 1
    page_size: int = 20


@dataclass(frozen=True)
class ListResult:
    items: list[Payment]
    total_count: int


class PaymentRepository(ABC):
    """Defines the persistence contract for the payment aggregate."""

    @abstractmethod
    def find_by_id(self, payment_id: str) -> Optional[Payment]:
        ...

    @abstractmethod
    def list_payments(self, filter_: PaymentFilter) -> ListResult:
        ...

    @abstractmethod
    def save(self, payment: Payment) -> None:
        ...
