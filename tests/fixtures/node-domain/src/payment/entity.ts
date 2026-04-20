/** Money is a value object representing a monetary amount with currency. */
export class Money {
  readonly amount: number;
  readonly currency: string;

  private constructor(amount: number, currency: string) {
    this.amount = amount;
    this.currency = currency;
  }

  static create(amount: number, currency: string): Money {
    if (amount < 0) throw new Error("amount must be non-negative");
    if (!currency) throw new Error("currency is required");
    return new Money(amount, currency);
  }
}

export type PaymentStatus = "pending" | "confirmed" | "cancelled";

export class InvalidTransitionError extends Error {
  constructor(from: PaymentStatus, to: string) {
    super(`invalid transition from ${from} to ${to}`);
    this.name = "InvalidTransitionError";
  }
}

/** Payment is the aggregate root for the payment domain. */
export class Payment {
  readonly id: string;
  readonly customerId: string;
  readonly amount: Money;
  private _status: PaymentStatus;
  readonly createdAt: Date;

  private constructor(id: string, customerId: string, amount: Money) {
    this.id = id;
    this.customerId = customerId;
    this.amount = amount;
    this._status = "pending";
    this.createdAt = new Date();
  }

  get status(): PaymentStatus {
    return this._status;
  }

  static create(id: string, customerId: string, amount: Money): Payment {
    if (!id) throw new Error("id is required");
    if (!customerId) throw new Error("customerId is required");
    return new Payment(id, customerId, amount);
  }

  confirm(): void {
    if (this._status !== "pending") {
      throw new InvalidTransitionError(this._status, "confirmed");
    }
    this._status = "confirmed";
  }

  cancel(): void {
    if (this._status === "cancelled") {
      throw new InvalidTransitionError(this._status, "cancelled");
    }
    this._status = "cancelled";
  }
}
