@_exported import Transaction

public final class PayPalPayment<P>: PaymentMethod where P: Buyable {
    public typealias Purchase = P
    
    public static var pendingPossible: Bool
    
    public static var preauthNeeded: Bool
    
    public static var name: String
    
    public static var slug: String
    
    public init(request: Request) {
        <#code#>
    }
    
    public func workThroughPendingTransactions() {
        <#code#>
    }
    
    public func createTransaction(from purchase: P, userId: Int, amount: Int?, status: P.PaymentStatus?, paymentInit: @escaping (P.ID, String, Int, Int) -> (P.Payment)) -> EventLoopFuture<P.Payment> {
        <#code#>
    }
    
    public func pay(for order: P, userId: Int, amount: Int, params: Codable?, paymentInit: @escaping (P.ID, String, Int, Int) -> (P.Payment)) throws -> EventLoopFuture<PaymentResponse<P>> {
        <#code#>
    }
    
    public func refund(payment: P.Payment, amount: Int?) -> EventLoopFuture<P.Payment> {
        <#code#>
    }
}
