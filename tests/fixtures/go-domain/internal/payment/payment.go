package payment

import (
	"errors"
	"time"
)

// Money is a value object representing a monetary amount with currency.
type Money struct {
	Amount   int64
	Currency string
}

func NewMoney(amount int64, currency string) (Money, error) {
	if amount < 0 {
		return Money{}, errors.New("amount must be non-negative")
	}
	if currency == "" {
		return Money{}, errors.New("currency is required")
	}
	return Money{Amount: amount, Currency: currency}, nil
}

// Status represents payment lifecycle state.
type Status string

const (
	StatusPending   Status = "pending"
	StatusConfirmed Status = "confirmed"
	StatusCancelled Status = "cancelled"
)

var (
	ErrInvalidTransition = errors.New("invalid status transition")
	ErrNotFound          = errors.New("payment not found")
)

// Payment is the aggregate root for the payment domain.
type Payment struct {
	ID         string
	CustomerID string
	Amount     Money
	Status     Status
	CreatedAt  time.Time
}

func NewPayment(id, customerID string, amount Money) (*Payment, error) {
	if id == "" {
		return nil, errors.New("id is required")
	}
	if customerID == "" {
		return nil, errors.New("customer_id is required")
	}
	return &Payment{
		ID:         id,
		CustomerID: customerID,
		Amount:     amount,
		Status:     StatusPending,
		CreatedAt:  time.Now(),
	}, nil
}

func (p *Payment) Confirm() error {
	if p.Status != StatusPending {
		return ErrInvalidTransition
	}
	p.Status = StatusConfirmed
	return nil
}

func (p *Payment) Cancel() error {
	if p.Status == StatusCancelled {
		return ErrInvalidTransition
	}
	p.Status = StatusCancelled
	return nil
}
