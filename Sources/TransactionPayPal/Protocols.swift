import DatabaseKit
import Transaction
import Foundation
import PayPal

/// A Swift model that acts as an internal payment model for a service.
public protocol ExecutablePayment {
    
    /// The total value of the payment, in the smallest representation of the currency as possible, i.e. cents.
    var total: Int { get }
    
    /// The currency code of the amount of the payment, i.e. `"USD"`.
    var currency: String { get }
    
    /// The ID of the payment stored in the third-party payment service.
    var externalID: String? { get }
}


/// A type that can be represented by a PayPal payment model.
public protocol PayPalPaymentRepresentable {
    
    /// A model that holds additional data for creating the PayPal payment.
    associatedtype Content
    
    /// Create a `PayPal.Payment` instance from a container and additional content.
    ///
    /// - Parameters:
    ///   - container: The container to create the payment on. You can use it to get services or a DB connection.
    ///   - content: Additional data you use to create the payment.
    ///
    /// - Returns: The new `PayPal.Payment` instance that will be sent to PayPal to be stored.
    func paypal(on container: Container, content: Content) -> Future<PayPal.Payment>
}

extension Currency: CurrencyProtocol {
    
    /// Gets a known currency based on its code:
    ///
    ///     Currency(code: "USD") // Optional(Currency(code: "USD", number: 840, e: 2, name: "United States dollar"))
    ///
    /// This initializer is case-insensative.
    ///
    /// - Parameter code: The 3 character code of the currency to get.
    public init?(rawValue: String) {
        self.init(code: rawValue)
    }
    
    /// The 3 character code that represents the currency, i.e. `USD`, `EUR`, `XXX`.
    public var rawValue: String {
        return self.code
    }
}

extension Currency: AmountConverter {
    
    /// Converts the amount of a transaction for a given currency to a format consumable by the third-party payment provider.
    ///
    /// - Parameters:
    ///   - amount: The amount for a transaction to convert.
    ///   - currency: The currency of the amount passed in.
    ///
    /// - Returns: The formatted amount.
    public func amount(for amount: Int, as currency: Currency) -> Decimal {
        let exponent = currency.e ?? 0
        let sign: FloatingPointSign = amount >= 0 ? .plus : .minus
        
        return Decimal(sign: sign, exponent: -exponent, significand: Decimal(amount))
    }
    
    /// Converts the amount of a transaction for a given currency to a format consumable by the third-party payment provider.
    ///
    /// - Parameter amount: The amount for a transaction to convert.
    ///
    /// - Returns: The formatted amount.
    public func amount(for amount: Int) -> Decimal {
        return self.amount(for: amount, as: self)
    }
}
