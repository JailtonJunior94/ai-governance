import { PaymentService } from "./service.js";
import { PaymentFilter } from "./repository.js";

interface Request {
  query: Record<string, string | undefined>;
}

interface Response {
  status(code: number): Response;
  json(body: unknown): void;
}

/** Handler exposes HTTP endpoints for payments. */
export class PaymentHandler {
  constructor(private readonly service: PaymentService) {}

  async listPayments(req: Request, res: Response): Promise<void> {
    const filter: PaymentFilter = {
      customerId: req.query["customer_id"],
      status: req.query["status"] as PaymentFilter["status"],
      page: parseInt(req.query["page"] ?? "1", 10),
      pageSize: parseInt(req.query["page_size"] ?? "20", 10),
    };

    try {
      const result = await this.service.listPayments(filter);
      res.status(200).json({
        items: result.items.map((p) => ({
          id: p.id,
          customer_id: p.customerId,
          amount: p.amount.amount,
          currency: p.amount.currency,
          status: p.status,
        })),
        total_count: result.totalCount,
        page: filter.page,
        page_size: filter.pageSize,
      });
    } catch {
      res
        .status(500)
        .json({ error: { code: "internal", message: "failed to list payments" } });
    }
  }
}
