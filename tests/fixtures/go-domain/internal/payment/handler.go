package payment

import (
	"encoding/json"
	"net/http"
	"strconv"
)

// Handler exposes HTTP endpoints for payments.
type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

type listResponse struct {
	Items      []*paymentDTO `json:"items"`
	TotalCount int           `json:"total_count"`
	Page       int           `json:"page"`
	PageSize   int           `json:"page_size"`
}

type paymentDTO struct {
	ID         string `json:"id"`
	CustomerID string `json:"customer_id"`
	Amount     int64  `json:"amount"`
	Currency   string `json:"currency"`
	Status     string `json:"status"`
}

func (h *Handler) ListPayments(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	page, _ := strconv.Atoi(q.Get("page"))
	pageSize, _ := strconv.Atoi(q.Get("page_size"))

	filter := Filter{
		CustomerID: q.Get("customer_id"),
		Status:     Status(q.Get("status")),
		Page:       page,
		PageSize:   pageSize,
	}

	result, err := h.service.ListPayments(r.Context(), filter)
	if err != nil {
		http.Error(w, `{"error":{"code":"internal","message":"failed to list payments"}}`, http.StatusInternalServerError)
		return
	}

	items := make([]*paymentDTO, 0, len(result.Items))
	for _, p := range result.Items {
		items = append(items, &paymentDTO{
			ID:         p.ID,
			CustomerID: p.CustomerID,
			Amount:     p.Amount.Amount,
			Currency:   p.Amount.Currency,
			Status:     string(p.Status),
		})
	}

	resp := listResponse{
		Items:      items,
		TotalCount: result.TotalCount,
		Page:       filter.Page,
		PageSize:   filter.PageSize,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}
