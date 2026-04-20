import { Payment, PaymentStatus } from "./entity.js";

export interface PaymentFilter {
  customerId?: string;
  status?: PaymentStatus;
  page: number;
  pageSize: number;
}

export interface ListResult {
  items: Payment[];
  totalCount: number;
}

/** Repository defines the persistence contract for the payment aggregate. */
export interface PaymentRepository {
  findById(id: string): Promise<Payment | null>;
  list(filter: PaymentFilter): Promise<ListResult>;
  save(payment: Payment): Promise<void>;
}
