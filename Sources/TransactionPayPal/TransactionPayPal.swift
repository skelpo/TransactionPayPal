@_exported import Transaction
import Vapor
import PayPal
import Service

public final class PayPalPayment<Prc, Pay>: TransactionPaymentMethod
    where Prc: PaymentRepresentable & PayPalPaymentRepresentable, Prc.Content== Prc.PaymentContent, Prc.Payment == Pay, Pay: ExecutablePayment
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
    
    
    // MARK: - Init
    public init(container: Container) {
        self.container = container
    }
    
    
    // MARK: - PaymentMethod
    public func payment(for purchase: Prc, with content: Prc.PaymentContent) -> EventLoopFuture<Pay> {
        return Future.flatMap(on: self.container) { () -> Future<PayPal.Payment> in
            let payments = try self.container.make(Payments.self)
            let paypal = purchase.paypal(on: self.container, content: content).and(result: Optional<String>.none)
            return paypal.flatMap(payments.create)
        }.flatMap { paypal -> Future<Pay> in
            return purchase.payment(on: self.container, with: self, content: content, externalID: paypal.id)
        }
    }
    
    public func execute(payment: Pay, with data: AcceptQueryString) -> EventLoopFuture<Pay> {
        return Future.flatMap(on: self.container) {
            let payments = try self.container.make(Payments.self)
            
            let currency = Currency(rawValue: payment.currency) ?? .usd
            let executor = try PayPal.Payment.Executor(payer: data.payerID, amounts: [
                DetailedAmount(currency: currency, total: currency.amount(for: payment.total), details: nil)
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
    
        guard let external = payment.externalID else {
            return self.container.future(error:
                Abort(.custom(code: 418, reasonPhrase: "I'm a Teapot"), reason: "Unable to get ID for PayPal payment to refund")
            )
        }
        
        return payments.get(payment: external).flatMap { external in
            guard let id = external.id else {
                throw PayPalError(status: .failedDependency, identifier: "noID", reason: "Cannot get ID for a PayPal payment")
            }
            let currency = Currency(rawValue: payment.currency) ?? .usd
            let refund = try PayPal.Payment.Refund(
                amount: DetailedAmount(currency: currency, total: currency.amount(for: payment.total), details: nil),
                description: nil,
                reason: nil,
                invoice: nil
            )
            
            return payments.refund(sale: id, with: refund).transform(to: payment)
        }
    }
}


// MARK: - PaymentResponse
extension PayPalPayment: PaymentResponse where Pay: Content {
    public typealias CreatedResponse = LinkDescription
    public typealias ExecutedResponse = Pay
    
    public func created(from payment: Pay) -> Future<LinkDescription> {
        return Future.flatMap(on: self.container) { () -> Future<PayPal.Payment> in
            let payments = try self.container.make(Payments.self)
            guard let external = payment.externalID else {
                throw Abort(.custom(code: 418, reasonPhrase: "I'm a Teapot"), reason: "Unable to get ID for Stripe payment to refund")
            }
            
            return payments.get(payment: external)
        }.map { payment in
            guard let redirect = payment.links?.filter({ $0.rel == "approval_url" }).first else {
                throw Abort(.failedDependency, reason: "Cannot get payment approval URL")
            }
            return redirect
        }
    }
    
    public func executed(from payment: Pay) -> Future<Pay> {
        return self.container.future(payment)
    }
}
