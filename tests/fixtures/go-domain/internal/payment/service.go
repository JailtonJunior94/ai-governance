package payment

import (
	"context"
	"errors"
)

// Service orchestrates payment use cases.
type Service struct {
	repo Repository
}

func NewService(repo Repository) (*Service, error) {
	if repo == nil {
		return nil, errors.New("repository is required")
	}
	return &Service{repo: repo}, nil
}

func (s *Service) ListPayments(ctx context.Context, filter Filter) (*ListResult, error) {
	if filter.Page < 1 {
		filter.Page = 1
	}
	if filter.PageSize < 1 || filter.PageSize > 100 {
		filter.PageSize = 20
	}
	return s.repo.List(ctx, filter)
}

func (s *Service) ConfirmPayment(ctx context.Context, id string) error {
	p, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return err
	}
	if err := p.Confirm(); err != nil {
		return err
	}
	return s.repo.Save(ctx, p)
}
