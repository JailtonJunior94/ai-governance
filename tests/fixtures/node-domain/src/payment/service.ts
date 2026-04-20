import { PaymentRepository, PaymentFilter, ListResult } from "./repository.js";

/** Service orchestrates payment use cases. */
export class PaymentService {
  constructor(private readonly repo: PaymentRepository) {}

  async listPayments(filter: PaymentFilter): Promise<ListResult> {
    const sanitized: PaymentFilter = {
      ...filter,
      page: filter.page < 1 ? 1 : filter.page,
      pageSize:
        filter.pageSize < 1 || filter.pageSize > 100 ? 20 : filter.pageSize,
    };
    return this.repo.list(sanitized);
  }

  async confirmPayment(id: string): Promise<void> {
    const payment = await this.repo.findById(id);
    if (!payment) throw new Error("payment not found");
    payment.confirm();
    await this.repo.save(payment);
  }
}
