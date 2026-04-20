"""Payment use cases."""

from __future__ import annotations

from .entity import Payment
from .repository import PaymentFilter, PaymentRepository, ListResult


class PaymentService:
    """Orchestrates payment use cases."""

    def __init__(self, repo: PaymentRepository) -> None:
        if repo is None:
            raise ValueError("repository is required")
        self._repo = repo

    def list_payments(self, filter_: PaymentFilter) -> ListResult:
        page = filter_.page if filter_.page >= 1 else 1
        page_size = filter_.page_size if 1 <= filter_.page_size <= 100 else 20
        sanitized = PaymentFilter(
            customer_id=filter_.customer_id,
            status=filter_.status,
            page=page,
            page_size=page_size,
        )
        return self._repo.list_payments(sanitized)

    def confirm_payment(self, payment_id: str) -> None:
        payment = self._repo.find_by_id(payment_id)
        if payment is None:
            raise ValueError("payment not found")
        payment.confirm()
        self._repo.save(payment)
