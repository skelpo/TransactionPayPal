import Vapor

/// The query-string values received from PayPal after a transaction is approved.
public struct AcceptQueryString: Content {
    
    /// The ID of the payer for the transaction.
    public let payerID: String
    
    /// The ID of the transaction's payment.
    public let paymentID: String
}
