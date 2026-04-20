"""Tests for payment entity invariants."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))

import pytest
from payment.entity import Money, Payment, PaymentStatus, InvalidTransitionError


class TestMoney:
    def test_valid_money(self):
        m = Money(amount=1000, currency="BRL")
        assert m.amount == 1000
        assert m.currency == "BRL"

    def test_negative_amount(self):
        with pytest.raises(ValueError, match="non-negative"):
            Money(amount=-1, currency="BRL")

    def test_empty_currency(self):
        with pytest.raises(ValueError, match="currency"):
            Money(amount=100, currency="")

    def test_immutable(self):
        m = Money(amount=100, currency="USD")
        with pytest.raises(AttributeError):
            m.amount = 200


class TestPayment:
    def _make_payment(self, **kwargs):
        defaults = {"id": "pay-1", "customer_id": "cust-1", "amount": Money(500, "USD")}
        defaults.update(kwargs)
        return Payment(**defaults)

    def test_creates_with_pending(self):
        p = self._make_payment()
        assert p.status == PaymentStatus.PENDING

    def test_empty_id(self):
        with pytest.raises(ValueError, match="id"):
            self._make_payment(id="")

    def test_empty_customer_id(self):
        with pytest.raises(ValueError, match="customer_id"):
            self._make_payment(customer_id="")

    def test_confirm_from_pending(self):
        p = self._make_payment()
        p.confirm()
        assert p.status == PaymentStatus.CONFIRMED

    def test_confirm_from_confirmed_fails(self):
        p = self._make_payment()
        p.confirm()
        with pytest.raises(InvalidTransitionError):
            p.confirm()

    def test_cancel_from_pending(self):
        p = self._make_payment()
        p.cancel()
        assert p.status == PaymentStatus.CANCELLED

    def test_cancel_from_cancelled_fails(self):
        p = self._make_payment()
        p.cancel()
        with pytest.raises(InvalidTransitionError):
            p.cancel()
