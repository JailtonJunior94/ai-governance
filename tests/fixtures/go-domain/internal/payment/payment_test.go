package payment

import (
	"testing"
)

func TestNewMoney_ValidInput(t *testing.T) {
	m, err := NewMoney(1000, "BRL")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if m.Amount != 1000 || m.Currency != "BRL" {
		t.Errorf("got %+v, want {Amount:1000, Currency:BRL}", m)
	}
}

func TestNewMoney_NegativeAmount(t *testing.T) {
	_, err := NewMoney(-1, "BRL")
	if err == nil {
		t.Fatal("expected error for negative amount")
	}
}

func TestNewMoney_EmptyCurrency(t *testing.T) {
	_, err := NewMoney(100, "")
	if err == nil {
		t.Fatal("expected error for empty currency")
	}
}

func TestNewPayment_ValidInput(t *testing.T) {
	amount, _ := NewMoney(500, "USD")
	p, err := NewPayment("pay-1", "cust-1", amount)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if p.Status != StatusPending {
		t.Errorf("initial status = %s, want pending", p.Status)
	}
}

func TestNewPayment_EmptyID(t *testing.T) {
	amount, _ := NewMoney(500, "USD")
	_, err := NewPayment("", "cust-1", amount)
	if err == nil {
		t.Fatal("expected error for empty id")
	}
}

func TestNewPayment_EmptyCustomerID(t *testing.T) {
	amount, _ := NewMoney(500, "USD")
	_, err := NewPayment("pay-1", "", amount)
	if err == nil {
		t.Fatal("expected error for empty customer_id")
	}
}

func TestPayment_Confirm_FromPending(t *testing.T) {
	amount, _ := NewMoney(500, "USD")
	p, _ := NewPayment("pay-1", "cust-1", amount)

	if err := p.Confirm(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if p.Status != StatusConfirmed {
		t.Errorf("status = %s, want confirmed", p.Status)
	}
}

func TestPayment_Confirm_FromConfirmed_Fails(t *testing.T) {
	amount, _ := NewMoney(500, "USD")
	p, _ := NewPayment("pay-1", "cust-1", amount)
	p.Confirm()

	err := p.Confirm()
	if err != ErrInvalidTransition {
		t.Errorf("error = %v, want ErrInvalidTransition", err)
	}
}

func TestPayment_Cancel_FromPending(t *testing.T) {
	amount, _ := NewMoney(500, "USD")
	p, _ := NewPayment("pay-1", "cust-1", amount)

	if err := p.Cancel(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if p.Status != StatusCancelled {
		t.Errorf("status = %s, want cancelled", p.Status)
	}
}

func TestPayment_Cancel_FromCancelled_Fails(t *testing.T) {
	amount, _ := NewMoney(500, "USD")
	p, _ := NewPayment("pay-1", "cust-1", amount)
	p.Cancel()

	err := p.Cancel()
	if err != ErrInvalidTransition {
		t.Errorf("error = %v, want ErrInvalidTransition", err)
	}
}
