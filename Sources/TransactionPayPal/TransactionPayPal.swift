@_exported import Transaction
import Service

public final class PayPalPayment<P>: PaymentMethod where P: Buyable {
    public typealias Purchase = P
    
    public static var pendingPossible: Bool { return true }
    public static var preauthNeeded: Bool { return true }
    public static var name: String { return "PayPal Payment" }
    public static var slug: String { return "paypalPayment" }
    
    public let container: Container
    
    public init(container: Container) {
        self.container = container
    }
    
    public static func makeService(for worker: Container) throws -> PayPalPayment<P> {
        return PayPalPayment<P>.init(container: worker)
    }
    
    public func workThroughPendingTransactions() {
        fatalError()
    }
    
    public func createTransaction(from purchase: P, userId: Int, amount: Int?, status: P.PaymentStatus?, paymentInit: @escaping (P.ID, String, Int, Int) -> (P.Payment)) -> EventLoopFuture<P.Payment> {
        fatalError()
    }
    
    public func pay(for order: P, userId: Int, amount: Int, params: Codable?, paymentInit: @escaping (P.ID, String, Int, Int) -> (P.Payment)) throws -> EventLoopFuture<PaymentResponse<P>> {
        fatalError()
    }
    
    public func refund(payment: P.Payment, amount: Int?) -> EventLoopFuture<P.Payment> {
        fatalError()
    }
}
