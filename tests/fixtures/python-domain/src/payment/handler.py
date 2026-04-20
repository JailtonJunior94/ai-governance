"""HTTP handler for payment endpoints."""

from __future__ import annotations

from dataclasses import asdict
from typing import Any, Optional

from .entity import PaymentStatus
from .repository import PaymentFilter
from .service import PaymentService


class PaymentHandler:
    """Exposes HTTP endpoints for payments."""

    def __init__(self, service: PaymentService) -> None:
        self._service = service

    def list_payments(
        self,
        customer_id: Optional[str] = None,
        status: Optional[str] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> dict[str, Any]:
        status_enum = PaymentStatus(status) if status else None
        filter_ = PaymentFilter(
            customer_id=customer_id,
            status=status_enum,
            page=page,
            page_size=page_size,
        )
        result = self._service.list_payments(filter_)
        return {
            "items": [
                {
                    "id": p.id,
                    "customer_id": p.customer_id,
                    "amount": p.amount.amount,
                    "currency": p.amount.currency,
                    "status": p.status.value,
                }
                for p in result.items
            ],
            "total_count": result.total_count,
            "page": filter_.page,
            "page_size": filter_.page_size,
        }
