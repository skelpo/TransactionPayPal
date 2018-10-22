import DatabaseKit
import Transaction
import Foundation
import PayPal

public protocol ExecutablePayment {
    var total: Int { get }
    var currency: String { get }
    var externalID: String? { get set }
}

public protocol PayPalPaymentRepresentable {
    associatedtype Content
    
    func paypal(on container: Container, content: Content) -> Future<PayPal.Payment>
}

extension Currency: CurrencyProtocol {
    public init?(rawValue: String) {
        self.init(code: rawValue)
    }
    
    public var rawValue: String {
        return self.code
    }
}

extension Currency: AmountConverter {
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
    
    public func amount(for amount: Int) -> String {
        return self.amount(for: amount, as: self)
    }
}
