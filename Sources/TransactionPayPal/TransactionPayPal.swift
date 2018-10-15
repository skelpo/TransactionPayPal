@_exported import Transaction
import Vapor
import PayPal
import Service

public final class PayPalPayment<Prc, Pay>: TransactionPaymentMethod, AmountConverter
    where Prc: PaymentRepresentable, Prc.Payment == Pay, Pay: ExecutablePayment
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
    public func payment(for purchase: Prc) -> EventLoopFuture<Pay> {
        return Future.flatMap(on: self.container) { () -> Future<PayPal.Payment> in
            let payments = try self.container.make(Payments.self)
            
            guard let request = self.container as? Request else {
                throw Abort(.internalServerError, reason: "Attempted to decode a PayPal type payment from a non-request container")
            }
            
            let payment: Future<(PayPal.Payment, String?)> = try request.content.decode(PayPal.Payment.self).and(result: nil)
            return payment.flatMap(payments.create)
        }.flatMap { payment in
            return purchase.payment(on: self.container, with: self, externalID: payment.id)
        }
    }
    
    public func execute(payment: Pay, with data: AcceptQueryString) -> EventLoopFuture<Pay> {
        return Future.flatMap(on: self.container) {
            let payments = try self.container.make(Payments.self)
            
            let currency = Currency(rawValue: payment.currency) ?? .usd
            let executor = try PayPal.Payment.Executor(payer: data.payerID, amounts: [
                DetailedAmount(currency: currency, total: self.amount(for: payment.total, as: currency), details: nil)
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
                amount: DetailedAmount(currency: currency, total: self.amount(for: payment.total, as: currency), details: nil),
                description: nil,
                reason: nil,
                invoice: nil
            )
            
            return payments.refund(sale: id, with: refund).transform(to: payment)
        }
    }
    
    public func amount(for amount: Int, as currency: Currency) -> String {
        let exponent = currency.e ?? 0
        
        var string = String(describing: amount)
        
        if exponent == 0 {
            return string
        }
        if string.count > exponent {
            string.insert(".", at: string.index(string.endIndex, offsetBy: -exponent))
        } else {
            return "0." + String(repeating: "0", count: exponent - string.count) + string
        }
        return string
    }
}


// MARK: - PaymentResponse
extension PayPalPayment: PaymentResponse where Pay: Content {
    public typealias CreatedResponse = Response
    public typealias ExecutedResponse = Response
    
    public func created(from payment: Pay) -> Future<Response> {
        return Future.flatMap(on: self.container) { () -> Future<PayPal.Payment> in
            let payments = try self.container.make(Payments.self)
            guard let external = payment.externalID else {
                throw Abort(.custom(code: 418, reasonPhrase: "I'm a Teapot"), reason: "Unable to get ID for Stripe payment to refund")
            }
            
            return payments.get(payment: external)
        }.map { payment -> Response in
            guard let redirect = payment.links?.filter({ $0.rel == "approval_url" }).first?.href else {
                throw Abort(.failedDependency, reason: "Cannot get payment approval URL")
            }
            
            let response = Response(using: self.container)
            response.http.status = .seeOther
            response.http.headers.replaceOrAdd(name: .location, value: redirect)
            
            return response
        }
    }
    
    public func executed(from payment: Pay) -> Future<Response> {
        return Future.map(on: self.container) {
            let response = Response(using: self.container)
            try response.content.encode(payment)
            return response
        }
    }
}
