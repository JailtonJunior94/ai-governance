package payment

import "context"

// Filter holds query parameters for listing payments.
type Filter struct {
	CustomerID string
	Status     Status
	Page       int
	PageSize   int
}

// ListResult holds paginated results.
type ListResult struct {
	Items      []*Payment
	TotalCount int
}

// Repository defines the persistence contract for the payment aggregate.
type Repository interface {
	FindByID(ctx context.Context, id string) (*Payment, error)
	List(ctx context.Context, filter Filter) (*ListResult, error)
	Save(ctx context.Context, payment *Payment) error
}
