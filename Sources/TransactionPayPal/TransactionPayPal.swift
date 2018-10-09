@_exported import Transaction
import PayPal
import Service

public final class PayPalPayment<Prc, Pay>: TransactionPaymentMethod
    where Prc: PaymentRepresentable & PaymentCreator, Prc.Payment == Pay, Pay: ExecutablePayment
{
    
    // MARK: - Types
    public typealias Purchase = Prc
    public typealias Payment = Pay
    public typealias ExecutionData = AcceptQueryString
    
    
    // MARK: - Properties
    public static var name: String {
        return "PayPal Payment"
    }
    public static var slug: String {
        return "paypal"
    }
    
    public let container: Container
    
    
    // MARK: - Methods
    public init(container: Container) {
        self.container = container
    }
    
    public func payment(for purchase: Prc) -> EventLoopFuture<Pay> {
        return Future.flatMap(on: self.container) { () -> Future<PayPal.Payment> in
            let payments = try self.container.make(Payments.self)
            return payments.create(payment: purchase.paypal)
        }.flatMap { payment in
            return purchase.payment(on: self.container, with: self)
        }
    }
    
    public func execute(payment: Pay, with data: AcceptQueryString) -> EventLoopFuture<Pay> {
        return Future.flatMap(on: self.container) {
            let payments = try self.container.make(Payments.self)
            let executor = try PayPal.Payment.Executor(payer: data.payerID, amounts: [
                DetailedAmount(currency: payment.currency, total: payment.total, details: nil)
            ])
            
            return payments.execute(payment: data.paymentID, with: executor).transform(to: payment)
        }
    }
    
    public func refund(payment: Pay, amount: Int?) -> EventLoopFuture<Pay> {
        let payments: Payments
        
        do {
            payments = try self.container.make(Payments.self)
        } catch let error {
            return self.container.future(error: error)
        }
            
        return payments.get(payment: payment.externalID).flatMap { external in
            guard let id = external.id else {
                throw PayPalError(status: .failedDependency, identifier: "noID", reason: "Cannot get ID for a PayPal payment")
            }
            let refund = try PayPal.Payment.Refund(
                amount: DetailedAmount(currency: payment.currency, total: payment.total, details: nil),
                description: nil,
                reason: nil,
                invoice: nil
            )
            
            return payments.refund(sale: id, with: refund).transform(to: payment)
        }
    }
}
